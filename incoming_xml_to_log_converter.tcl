when HTTP_REQUEST {
    log local0. "[virtual] Source IP: [IP::client_addr]"

    # Initialize the content length variable to 0.
    set cl 0

    # If there is Content-Length header regardless the HTTP method is,
    if { [HTTP::header "Content-Length"] ne "" } {
        # and the value is bigger than 0,
        if { [HTTP::header "Content-Length"] > 0 } {
            # then update the variable,
            set cl [HTTP::header "Content-Length"]
            # and trigger the payload collection. 
            # This will trigger the HTTP_REQUEST_DATA event.
            HTTP::collect $cl
        }
    }
}

when HTTP_REQUEST_DATA {

    # Assumed the payload has been fully collected at this point so there is no 
    # length check.

    # The XML payload from the sample is a debug message containing debug 
    # stages from request received until response sent. The most complete 
    # headers are from the REQ_START and PROXY_POST_RESP_SENT.

    # Let's start with finding the request information.
    set method ""
    array set reqhdrs {}
    set uri ""
    set reqcntt ""
    set reqcnttln ""
    # Find the REQ_START position.
    set tagreqpos [string first "REQ_START" [HTTP::payload] 0]
    # If it is found,
    if { ($tagreqpos != -1) && ($tagreqpos > 0) } {
        # Find the content inside <Content> and </Content> tags.
        set cntt_start [string first "<Content>" [HTTP::payload] $tagreqpos]
        set cntt_end [string first "</Content>" [HTTP::payload] $tagreqpos]
        if { ($cntt_start != -1) && ($cntt_end != -1) } {
            set reqcntt [string range [HTTP::payload] [expr {$cntt_start + 9}] [expr {$cntt_end - 1}]]
            set reqcnttln [string length $reqcntt]
        }
        # Find the <Headers> and </Headers> position
        set hdrs_start [string first "<Headers>" [HTTP::payload] $tagreqpos]
        set hdrs_end [string first "</Headers>" [HTTP::payload] $tagreqpos]
        if { ($hdrs_start != -1) && ($hdrs_end != -1)} {
            # Copy the headers to a separate space.
            set hdrs [string range [HTTP::payload] [expr {$hdrs_start + 9}] $hdrs_end]
            set hdrsln [string length $hdrs]
            # Parse the header one-by-one.
            set hdr_start 0
            set hdr_end 0
            set i 0
            while { $i < $hdrsln } {
                set hdr_start [string first "<Header " $hdrs $i]
                set hdr_end [string first "</Header>" $hdrs $i]
                if { $hdr_start != -1 } {
                    set hdr [string range $hdrs $hdr_start $hdr_end]
                    set hdr_list [split $hdr \"><]
                    set hdr_name [lindex $hdr_list 2]
                    set hdr_value [lindex $hdr_list 4]
                    set reqhdrs($hdr_name) $hdr_value
                    set i [expr { $hdr_end + 9}]
                } else {
                    # Loop breaker if the header start tag is not found.
                    set i $hdrsln
                }
            }
        }
        # (for checking) Dump request headers to log. 
        #foreach nm [array names reqhdrs] {
        #    set val $reqhdrs($nm)
        #    log local0. "nm: $nm ; val: $val"
        #}

        # Find the <URI> and </URI> position.
        set uri_start [string first "<URI>" [HTTP::payload] $tagreqpos]
        set uri_end [string first "</URI>" [HTTP::payload] $tagreqpos]
        if { ($uri_start != -1) && ($uri_end != -1) } {
            # Copy the URI to a separate variable.
            set uri [string range [HTTP::payload] [expr {$uri_start + 5}] [expr {$uri_end - 1}]]
            #log local0. "uri: $uri"
        }

        # Find the method inside <Verb> and </Verb> position.
        set method_start [string first "<Verb>" [HTTP::payload] $tagreqpos]
        set method_end [string first "</Verb>" [HTTP::payload] $tagreqpos]
        if { ($method_start != -1) && ($method_end != -1) } {
            # Copy the method to a separate variable.
            set method [string range [HTTP::payload] [expr {$method_start + 6}] [expr {$method_end - 1}]]
            #log local0. "method: $method"
        }
    }

    # At this point, we got all the request part to be sent to XC.
    # Let's find the response information.
    set reasonphrase ""
    set rescntt ""
    set rescnttln 0
    array set reshdrs {}
    set statuscode ""
    # Find the PROXY_POST_RESP_SENT position.
    set tagrespos [string first "PROXY_POST_RESP_SENT" [HTTP::payload] 0]
    # If it is found,
    if { ($tagrespos != -1) && ($tagrespos > 0) } {
        # Find the content inside <Content> and </Content> tags.
        set cntt_start [string first "<Content>" [HTTP::payload] $tagrespos]
        set cntt_end [string first "</Content>" [HTTP::payload] $tagrespos]
        if { ($cntt_start != -1) && ($cntt_end != -1) } {
            set rescntt [string range [HTTP::payload] [expr {$cntt_start + 9}] [expr {$cntt_end - 1}]]
            set rescnttln [string length $rescntt]
        }
        # Then find the <StatusCode>
        set stc_start [string first "<StatusCode>" [HTTP::payload] $tagrespos]
        set stc_end [string first "</StatusCode>" [HTTP::payload] $tagrespos]
        if { ($stc_start != -1) && ($stc_end != -1) } {
            set statuscode [string range [HTTP::payload] [expr {$stc_start + 12}] [expr {$stc_end - 1}]]
        }
        # Then find the <ReasonPhrase>
        set rp_start [string first "<ReasonPhrase>" [HTTP::payload] $tagrespos]
        set rp_end [string first "</ReasonPhrase>" [HTTP::payload] $tagrespos]
        if { ($rp_start != -1) && ($rp_end != -1) } {
            set reasonphrase [string range [HTTP::payload] [expr {$rp_start + 14}] [expr {$rp_end - 1}]]
        }
        # Find the <Headers> and </Headers> position
        set hdrs_start [string first "<Headers>" [HTTP::payload] $tagrespos]
        set hdrs_end [string first "</Headers>" [HTTP::payload] $tagrespos]
        if { ($hdrs_start != -1) && ($hdrs_end != -1)} {
            # Copy the headers to a separate space.
            set hdrs [string range [HTTP::payload] [expr {$hdrs_start + 9}] $hdrs_end]
            set hdrsln [string length $hdrs]
            # Parse the header one-by-one.
            set hdr_start 0
            set hdr_end 0
            set i 0
            while { $i < $hdrsln } {
                set hdr_start [string first "<Header " $hdrs $i]
                set hdr_end [string first "</Header>" $hdrs $i]
                if { $hdr_start != -1 } {
                    set hdr [string range $hdrs $hdr_start $hdr_end]
                    set hdr_list [split $hdr \"><]
                    set hdr_name [lindex $hdr_list 2]
                    set hdr_value [lindex $hdr_list 4]
                    set reshdrs($hdr_name) $hdr_value
                    set i [expr { $hdr_end + 9}]
                } else {
                    # Loop breaker if the header start tag is not found.
                    set i $hdrsln
                }
            }
        }
        # (for checking) Dump response headers to log. 
        #foreach nm [array names reshdrs] {
        #    set val $reshdrs($nm)
        #    log local0. "nm: $nm ; val: $val"
        #}
    }

    # The response content has been collected.
    # Next is to prepare the simulated request and simulated response.
    set simstatus ""

    # Generate unique value for X-F5XC-LinkId header to link with the response.
    set uuid [format %2.2x [clock seconds]]
    append uuid -[string range [format %2.2x [clock clicks]] 0 3]
    append uuid -[string range [format %2.2x [clock clicks]] 2 5]
    append uuid -[string range [format %2.2x [clock clicks]] 4 end]
    append uuid -[format %2.2x [expr { int(rand()*100000000000000) }]]

    # Create the request message from the collected contents.
    set simreq "$method $uri HTTP/1.1\n"
    #append simreq "Host: xc-oob.yuliantoro.com\n"
    foreach nm [array names reqhdrs] {
        set val $reqhdrs($nm)
        append simreq "$nm: $val\n"
    }
    append simreq "X-F5XC-LinkId: $uuid\n"
    append simreq "\n"
    if { $reqcnttln > 0 } {
        append simreq "$reqcntt"
    }
    # Add request content here if any
    #append simreq $reqcontent

    # Create the response message from the collected contents.
    set simreshdrs "X-XML-StatusCode $statuscode X-XML-ReasonPhrase \"$reasonphrase\" "
    foreach nm [array names reshdrs] {
        set val $reshdrs($nm)
        append simreshdrs "$nm \"$val\" "
    }
    append simreshdrs "X-F5XC-LinkId $uuid"
    #log local0. "X-F5XC-LinkId $uuid"
    set simrescntt ""
    if { $rescnttln > 0 } {
        append simreshdrs " Content-Length $rescnttln"
        set simrescntt $rescntt
    }
    # Store the simulated response in the memory using $uuid as key.
    table add hdrs$uuid $simreshdrs 600
    table add cntt$uuid $simrescntt 600
    # Estimated length of response
    set simresln [expr {[string length $simreshdrs] + [string length $simrescntt]}]

    # Establish connection to internal VS (for http-to-https conversion).
    if { [catch {connect -protocol TCP -status conn_status "/Common/xc-http-to-https"} conn] == 0 && $conn ne "" } {
        # Send the simulated request (including the checks).
        if { [catch {send -status send_status $conn $simreq} sent] == 0 } {
            if { $send_status eq "sent" } {
                set simreqln [string length $simreq]
                if { $sent == $simreqln } {
                    # Receive the simulated response.
                    set rcvd_data ""
                    set max_iterations 3
                    for { set i 0 } { $i < $max_iterations } { incr i } {
                        append rcvd_data [recv -timeout 1000 $conn]
                        if { [string length $rcvd_data] >= $simresln } {
                            break
                        }
                    }
                    # Close connection.
                    close $conn
                    if { [string length $rcvd_data] >= $simresln } {
                        set simstatus "OK: Simulated request has been sent and simulated response has been received."    
                    } else {
                        set rcvdlen [string length $rcvd_data]
                        set simstatus "Rcv For-Loop ended. rcvdlen: $rcvdlen ; simresln: $simresln.\nRcv_data:\n$rcvd_data"
                    }                    
                } else {
                    set simstatus "Failed to send completely: Only sent $sent bytes out of $simreqln bytes."
                }
            } else {
                set simstatus "Sent status not 'sent': $send_status."    
            }
        } else {
            set simstatus "Failed to send: $send_status."
        }
    } else {
        set simstatus "Failed to connect to the VS: $conn_status"
    }

    HTTP::payload replace 0 [HTTP::payload length] ""
    HTTP::release
    # Send the response
    HTTP::respond 200 -version auto content "$simstatus\n"    
}
