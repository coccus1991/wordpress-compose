vcl 4.0;

import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "nginx";
    .port = "8080";
    .connect_timeout = 600s;
    .first_byte_timeout = 600s;
    .between_bytes_timeout = 600s;
    .max_connections = 800;
}

# Only allow purging from specific IPs
acl purge {
    "localhost";
    "127.0.0.1";
    "192.168.0.0/16";
    "10.0.0.0/8";
    "172.16.0.0/12";
}

# This function is used when a request is send by a HTTP client (Browser)
sub vcl_recv {
	# Normalize the header, remove the port (in case you're testing this on various TCP ports)
	set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");


	# Allow purging from ACL
	if (req.method == "PURGE") {

		if(req.url ~ "^/\.\*$") {
		    ban("req.http.host == " +req.http.host+" && req.url ~ "+req.url);
		}

         if (client.ip ~ purge) {
		    return (purge);
          } else {
            return (synth(403, "Not allowed."));
          }
	}


	# Post requests will not be cached
	if (req.http.Authorization || req.method == "POST") {
		return (pass);
	}


	# Did not cache the admin and login pages
	if (req.url ~ "/wp-(login|admin)") {
		return (pass);
	}

	# Normalize Accept-Encoding header and compression
	# https://www.varnish-cache.org/docs/3.0/tutorial/vary.html
	if (req.http.Accept-Encoding) {
		# Do no compress compressed files...
		if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
			   	unset req.http.Accept-Encoding;
		} elsif (req.http.Accept-Encoding ~ "gzip") {
		    	set req.http.Accept-Encoding = "gzip";
		} elsif (req.http.Accept-Encoding ~ "deflate") {
		    	set req.http.Accept-Encoding = "deflate";
		} else {
			unset req.http.Accept-Encoding;
		}
	}

	# Check the cookies for wordpress-specific items
	if (req.http.Cookie ~ "wordpress_" || req.http.Cookie ~ "comment_") {
		return (pass);
	}


	# --- End of Wordpress specific configuration


	# Cache all others requests
	return (hash);
}

sub vcl_pipe {
	return (pipe);
}

sub vcl_pass {
	return (fetch);
}

# The data on which the hashing will take place
sub vcl_hash {
 	hash_data(req.url);

 	if (req.http.host) {
     	hash_data(req.http.host);
 	} else {
     	hash_data(server.ip);
 	}

	# If the client supports compression, keep that in a different cache
    	if (req.http.Accept-Encoding) {
        	hash_data(req.http.Accept-Encoding);
	}

	return (lookup);
}

# This function is used when a request is sent by our backend (Nginx server)
sub vcl_backend_response {
	# Remove some headers we never want to see
	unset beresp.http.Server;
	unset beresp.http.X-Powered-By;

	# For static content strip all backend cookies
	if (bereq.url ~ "\.(css|js|png|gif|jp(e?)g)|swf|ico") {
		unset beresp.http.cookie;
	}

	# Only allow cookies to be set if we're in admin area
	if (beresp.http.Set-Cookie && bereq.url !~ "^/wp-(login|admin)") {
        	unset beresp.http.Set-Cookie;
    }

	# don't cache response to posted requests or those with basic auth
	if ( bereq.method == "POST" || bereq.http.Authorization ) {
        	set beresp.uncacheable = true;
		    set beresp.ttl = 120s;
		    return (deliver);
    }

    # don't cache search results
	if ( bereq.url ~ "\?s=" ){
		set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
	}

	# only cache status ok
	if ( beresp.status != 200 ) {
		set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
	}


    # feed cache
	if (bereq.url ~ "/feed") {
		set beresp.ttl = 120s;
        return (deliver);
	}

    # overwrite ttl with X-VC-TTL
    if (beresp.http.X-VC-TTL) {
        set beresp.ttl = std.duration(beresp.http.X-VC-TTL + "s", 0s);
        return (deliver);
    }

	# A TTL of 24h
	set beresp.ttl = 24h;
	# Define the default grace period to serve cached content
	set beresp.grace = 30s;

	return (deliver);
}


sub vcl_hit {
    set req.http.X-Varnish-TTL = obj.ttl;
    return (deliver);
}

# The routine when we deliver the HTTP request to the user
# Last chance to modify headers that are sent to the client
sub vcl_deliver {
	if (obj.hits > 0) {
		set resp.http.X-Cache = "cached";
	} else {
		set resp.http.x-Cache = "uncached";
	}

    if (req.http.X-Varnish-TTL) {
      set resp.http.X-Varnish-TTL = req.http.X-Varnish-TTL;
      unset req.http.X-Varnish-TTL;
    }

	# Remove some headers: PHP version
	unset resp.http.X-Powered-By;

	# Remove some headers: Apache version & OS
	unset resp.http.Server;

	# Remove some heanders: Varnish
	unset resp.http.Via;

	unset resp.http.X-Varnish;

	return (deliver);
}

sub vcl_init {
 	return (ok);
}

sub vcl_fini {
 	return (ok);
}
