#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
#!!
#! @description: Performs a REST call to get details for a specified server.
#! @input host: OpenStack host
#! @input identity_port: optional - port used for OpenStack authentication - Default: '5000'
#! @input compute_port: optional - port used for OpenStack computations - Default: '8774'
#! @input tenant_name: name of OpenStack project that contains the server (instance) to be stopped
#! @input server_id: OpenStack server ID
#! @input username: optional - username used for URL authentication; for NTLM authentication - Format: 'domain\user'
#! @input password: optional - password used for URL authentication
#! @input proxy_host: optional - proxy server used to access OpenStack services
#! @input proxy_port: optional - proxy server port used to access OpenStack services - Default: '8080'
#! @input proxy_username: optional - username used when connecting to proxy
#! @input proxy_password: optional - proxy server password associated with <proxy_username> input value
#! @output return_result: response of operation in case of success, error message otherwise
#! @output error_message: return_result if status_code is not '200'
#! @output return_code: '0' if success, '-1' otherwise
#! @output status_code: the code returned by the operation
#! @result SUCCESS: details of OpenStack server (instance) was successfully retrieved
#! @result GET_AUTHENTICATION_FAILURE: authentication call fails
#! @result GET_AUTHENTICATION_TOKEN_FAILURE: authentication token cannot be obtained from authentication call response
#! @result GET_TENANT_ID_FAILURE: tenant_id corresponding to tenant_name cannot be obtained from authentication call response
#! @result GET_SERVER_DETAILS_FAILURE: details of the OpenStack server (instance) cannot be retrieved
#!!#
####################################################

namespace: io.cloudslang.cloud.openstack.servers

imports:
  rest: io.cloudslang.base.http
  openstack: io.cloudslang.cloud.openstack

flow:
  name: get_server_details
  inputs:
    - host:
        sensitive: true
    - identity_port:
        default: '5000'
        sensitive: true
    - compute_port:
        default: '8774'
        sensitive: true
    - tenant_name
    - server_id
    - username:
        required: false
        sensitive: true
    - password:
        required: false
        sensitive: true
    - proxy_host:
        required: false
        sensitive: true
    - proxy_port:
        default: '8080'
        required: false
        sensitive: true
    - proxy_username:
        required: false
        sensitive: true
    - proxy_password:
        required: false
        sensitive: true

  workflow:
    - authentication:
        do:
          openstack.get_authentication_flow:
            - host
            - identity_port
            - username
            - password
            - tenant_name
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
        publish:
          - return_result
          - error_message
          - token
          - tenant_id
        navigate:
          - SUCCESS: get_server_details
          - GET_AUTHENTICATION_FAILURE: GET_AUTHENTICATION_FAILURE
          - GET_AUTHENTICATION_TOKEN_FAILURE: GET_AUTHENTICATION_TOKEN_FAILURE
          - GET_TENANT_ID_FAILURE: GET_TENANT_ID_FAILURE

    - get_server_details:
        do:
          rest.http_client_get:
            - url: ${'http://'+ host + ':' + compute_port + '/v2/' + tenant_id + '/servers/' + server_id}
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - headers: ${'X-AUTH-TOKEN:' + token}
            - content_type: 'application/json'
        publish:
          - return_result
          - error_message
          - return_code
          - status_code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: GET_SERVER_DETAILS_FAILURE

  outputs:
    - return_result
    - error_message
    - return_code
    - status_code

  results:
    - SUCCESS
    - GET_AUTHENTICATION_FAILURE
    - GET_AUTHENTICATION_TOKEN_FAILURE
    - GET_TENANT_ID_FAILURE
    - GET_SERVER_DETAILS_FAILURE
