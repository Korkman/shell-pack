complete -c qcrypt -s h -l help -d "Show usage"
complete -c qcrypt -s e -l encrypt -d "Encrypt"
complete -c qcrypt -s d -l decrypt -d "Decrypt"
complete -c qcrypt -l gpg -d "Use GPG"
complete -c qcrypt -l openssl -d "Use OpenSSL (default)"
complete -c qcrypt -s t -l terminal -d "Allow terminals as stdin / stdout"
complete -c qcrypt -F
