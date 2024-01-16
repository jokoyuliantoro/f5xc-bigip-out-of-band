F5 XC with Out-of-Band BIG-IP.

Architecture:

![image](https://github.com/jokoyuliantoro/f5xc-bigip-out-of-band/assets/11230277/378af103-48d5-45bb-adde-06c1992e1245)


01_incoming_xml_to_log_converter => The injector upload XML trace to BIG-IP, parse it, construct simulated request+response and send the simulated request as HTTP request via sideband.

02_from_log_converter_to_f5xc => The 01_ iRule sends an HTTP request but XC receives only HTTPS. Hence, there is an HTTP-to-HTTPS VS with pool member pointing to XC.

03_incoming_from_f5xc => XC forwards the simulated request to BIG-IP and is received by this iRule to get the simulated response and send it as the reply.

![image](https://github.com/jokoyuliantoro/f5xc-bigip-out-of-band/assets/11230277/22aec689-a26e-4978-9a93-01c89c692036)

