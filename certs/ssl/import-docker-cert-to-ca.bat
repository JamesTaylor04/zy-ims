DEL ..\cacerts
COPY cacerts ../
keytool.exe -importcert -file docker-cert.pem -keystore ..\cacerts -storepass changeit