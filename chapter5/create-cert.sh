openssl genrsa -out tls.key 2048

openssl req -new -x509 -key tls.key -out tls.cert -days 360 -subj /CN=kubia.example.com

kubectl create secret tls tls-secret --cert=tls.cert --key=tls.key

kubectl get secrets