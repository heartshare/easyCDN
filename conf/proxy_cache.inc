proxy_cache nginx;
proxy_cache_key "$host$uri$is_args$args";
proxy_cache_valid 200 304 1d;