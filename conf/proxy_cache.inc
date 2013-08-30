proxy_set_header Host $host;
proxy_set_header Accept-Encoding '';
proxy_set_header Referer $http_referer;
proxy_set_header Cookie $http_cookie;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

proxy_cache nginx;
proxy_cache_key "$scheme://$host$request_uri";
proxy_cache_valid 200 301 302 304 1d;