when HTTP_REQUEST {
	log local0. "[virtual] Request from [IP::client_addr]"

    #foreach hdr [HTTP::header names] {
    #    log local0. "$hdr: [HTTP::header $hdr]"
    #}

	set xclinkid [HTTP::header X-F5XC-LinkId]
	if { $xclinkid ne "" } {
		set reshdrs [table lookup hdrs$xclinkid]
		set rescntt [table lookup cntt$xclinkid]
		if { $reshdrs ne "" } {
			log local0. "Found X-F5XC-LinkId: $xclinkid"
			log local0. "hdrs: $reshdrs"
			if { $rescntt ne "" } {
				HTTP::respond 200 -version auto content "$rescntt" $reshdrs
			} else {
				HTTP::respond 200 -version auto $reshdrs
			}			
		} else {
			HTTP::respond 200 -version auto content "OK\n\n"
		}
	} else {
		HTTP::respond 200 -version auto content "OK\n\n"
	}
}
