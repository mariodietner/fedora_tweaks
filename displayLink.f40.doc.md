# Introduction

This short description is used to document the neccesary steps i had to go through in order to make displayLink rpm package work on UEFI booted Fedora 40, version 6.10.12-200.fc40.x86_64.

# Prerequisites

- Download source code evdi-1.14.7.tar.gz, link: https://github.com/DisplayLink/evdi/releases
- Download displayLink driver rpm package fedora-40-displaylink-1.14.6-1.github_evdi.x86_64.rpm, link: https://github.com/displaylink-rpm/displaylink-rpm/releases
- preinstalled development tools and libs: dnf install pesign openssl kernel-devel mokutil keyutils gcc gcc-c++ libgcc

# Create Signing Keys

1. Generate private key

```
openssl genrsa -out pk.priv 2048
```

2. Generate self-signed cert, validity 10 years

```
openssl req -new -x509 -key pk.priv -out cert.pem -days 3650 -subj "/CN=mod sign/"
```

3. Convert keys to DER Fromat and load them into MOK

```
openssl x509 -in cert.pem -outform DER -out cert.der
```

# Import public certificate to MOK DB

```
sudo mokutil --import cert.der
```

- at this stage insert the password, that will be needed to import the key

# REBOOT

1. Reboot the machine and confirm the options to import the key to MOK.
2. After reboot, confirm the "mod sign" is part of the .platform keyring

```
sudo keyctl list %:.platform
```

# Import Signing keys to local NSS DB

##  1. <a name='Initializethedefaultetcpkipesigndatabasebutnotrequired'></a>Initialize the default /etc/pki/pesign database (but not required)

```
certutil -N -d sql:/etc/pki/pesign
```

##  2. <a name='ConvertPrivateandPublickeytop12'></a>Convert Private and Public key to p12

```
sudo openssl pkcs12 -export -inkey pk.priv -in cert.pem -out cert_and_key.p12 -name "mod sign"
```

##  3. <a name='Importthep12certificatetothenssdatabase'></a>Import the p12 certificate to the nss database

```
sudo pk12util -i cert_and_key.p12 -d sql:/etc/pki/pesign
```

##  4. <a name='CheckthecertificateModuleSigningKEyisinthedatabase'></a>Check the certificate "mod sign" is in the database

```
sudo certutil -L -d sql:/etc/pki/pesign
```

# Install Display Link

The reason why I install display link at this stage was, that it installs its included version of evdi interface, and i asume it deletes the one, which has to be created and signed in later stages. 

```
sudo dnf install fedora-40-displaylink-1.14.6-1.github_evdi.x86_64.rpm 
```

# Build EVDI source code

The easiest is to follow the instructions from EVDI. It was enough to use make in the top root Makefile. This created the module evdi.ko under /lib/modules/6.10.12-200.fc40.x86_64/kernel/drivers/gpu/drm/evdi/

Now, if you would wish to load the evdi module with /sbin/modprobe it would fail. So lets go ahead and sign the module with the private key. from the already imported public key. 

```
make
sudo make isntall (this may fail)
```

# Sign the module

```
sudo /usr/src/kernels/6.10.12-200.fc40.x86_64/scripts/sign-file sha256 pk.priv cert.pem /lib/modules/6.10.12-200.fc40.x86_64/kernel/drivers/gpu/drm/evdi/evdi.ko
```

# Verify the module

```
sudo modinfo /lib/modules/6.10.12-200.fc40.x86_64/kernel/drivers/gpu/drm/evdi/evdi.ko
```

And look for the Signind key "mod sign", which has to be in the module information.

# Load the module

```
sudo insmod /lib/modules/6.10.12-200.fc40.x86_64/kernel/drivers/gpu/drm/evdi/evdi.ko
```

# Connect the dock station or monitor over USB

Last but not least, the external monitor picture should turn on.

# Cleanup and Protect

Make sure the NSS is password protected and delete the keys from the file system. 