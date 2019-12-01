
server {
#    listen 80;
    server_name pickmybestphoto.com www.pickmybestphoto.com;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /var/www/pickmybestphoto.com/photovote;
    }


    ## prevent admin access by IP ##
    set $allow false;

    # check http_x_forwarded_for to get the actual IP
    if ($remote_addr = 68.20.16.81) {
       # matches an allowed IP, so set variable to true
       set $allow true;
    }


    # the admin subdirectory
    location /admin/ {
        # set the proxy to pass through to your upstream server (defined above)
        proxy_pass http://unix:/run/gunicorn.photovote.sock;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # if allow variable is still false, deny access
        if ($allow = false){ return 404;}
    }


    location / {

                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;

        proxy_pass http://unix:/run/gunicorn.photovote.sock;
    }



}


server {
    listen         80;
    return 301 https://$host$request_uri;
}

