cat <<EOF > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
 
events {
        worker_connections 768;
        # multi_accept on;
}
 
http {
 
        #resolver 192.168.1.1 192.168.1.2;
        #resolver_timeout 30s;
 
        proxy_read_timeout 300;
        proxy_connect_timeout 60;
        proxy_send_timeout 60;
        ##
        # Basic Settings
        ##
        log_format ssl_client
        '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $body_bytes_sent '
        '"Client fingerprint" $ssl_client_fingerprint '
        '"Client DN" $ssl_client_s_dn';
        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
        server_tokens off;
 
        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;
 
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
 
        ##
        # SSL Settings
        ##
 
        ssl_protocols TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;
 
        ##
        # Logging Settings
        ##
 
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
        client_max_body_size 50M;
        ##
        # Gzip Settings
        ##
 
        gzip on;
 
        ##
        # Virtual Host Configs
        ##
 
        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}
EOF

cat <<EOF > /etc/nginx/sites-available/proxy.example.home.conf
server {
 
    server_name proxy.example.home;
 
    location / {
            proxy_no_cache 1;
            proxy_cache_bypass 1;
            proxy_http_version 1.1;
            proxy_cache_bypass $http_upgrade;
            resolver 192.168.1.1 192.168.1.2;
            resolver_timeout 30s;
            set $backend http://dynamic.name.exampple.home:8091;
 
            if ($ssl_client_verify != SUCCESS) {
                return 403;
            }
 
            if ($ssl_client_fingerprint = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ) {
                proxy_pass $backend;
                break;
            }
 
            return 404;
        }
 
    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/proxy.example.home/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/proxy.example.home
    privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
 
    ssl_client_certificate /etc/nginx/client_certs/ca.crt;
    ssl_verify_client optional;
    ssl_verify_depth 10;
 
}
 
server {
    if ($host = proxy.example.home) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
 
    server_name proxy.example.home;
    listen 80;
    listen [::]:80;
    return 404; # managed by Certbot
}
 
EOF
