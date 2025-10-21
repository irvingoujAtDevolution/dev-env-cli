# Set environment variables for OpenSSL
$env:OPENSSL_DIR = "C:\Program Files\OpenSSL-Win64"
$env:OPENSSL_LIB_DIR = "C:\Program Files\OpenSSL-Win64\lib"
$env:OPENSSL_INCLUDE_DIR = "C:\Program Files\OpenSSL-Win64\include"

# Add OpenSSL bin to the PATH for this session
$env:PATH = "C:\Program Files\OpenSSL-Win64\bin;" + $env:PATH
