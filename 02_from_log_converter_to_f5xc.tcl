#when CLIENT_ACCEPTED {
#    log local0. "Connection from [IP::client_addr]"
#}

when HTTP_REQUEST {
    log local0. "New converted log coming"
    log local0. "Request Headers Start"
    foreach hdr [HTTP::header names] {
        log local0. "$hdr: [HTTP::header $hdr]"
    }
    log local0. "Request Headers End"
}

when SERVER_CONNECTED {
    log local0. "Connected to [IP::server_addr]"
}

#when SERVERSSL_CLIENTHELLO_SEND {
#    log local0. "-"
#}

#when SERVERSSL_SERVERCERT {
#    set result [X509::verify_cert_error_string [SSL::verify_result]]
#    log local0. "result: $result"
#}

#when SERVERSSL_SERVERHELLO {
#    log local0. "-"
#}

#when SERVERSSL_HANDSHAKE {
#    log local0. "-"
#}

when HTTP_RESPONSE {
    log local0. "Response received:"
    log local0. "Status Code: [HTTP::status]"
    log local0. "Response Headers Start"
    foreach hdr [HTTP::header names] {
        log local0. "$hdr: [HTTP::header $hdr]"
    }
    log local0. "Response Headers End"
    #log local0. "response: [string range [HTTP::response] 0 15]...\[trunc\]"
}
