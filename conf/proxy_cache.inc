proxy_redirect off;
proxy_buffer_size 16k;
proxy_buffers 8 32k;
proxy_busy_buffers_size 64k;
proxy_cache_path /tmp/nginx/cache levels=1:2 keys_zone=nginx:64m inactive=1d max_size=2g;
proxy_connect_timeout 30;
proxy_ignore_headers Set-Cookie Cache-Control Expires;
proxy_read_timeout  60;
proxy_send_timeout  30;
proxy_temp_file_write_size 64k;

proxy_set_header Host $host;
proxy_set_header Accept-Encoding '';
proxy_set_header Referer $http_referer;
proxy_set_header Cookie $http_cookie;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

proxy_cache nginx;
proxy_cache_key "$scheme://$host$request_uri";
proxy_cache_valid 200 301 302 304 1d;

proxy_pass http://ORIGIN_DOMAIN;
add_header Cache-Status $upstream_cache_status;