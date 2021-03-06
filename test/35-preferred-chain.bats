#! /usr/bin/env bats

load '/bats-support/load.bash'
load '/bats-assert/load.bash'
load '/getssl/test/test_helper.bash'


# This is run for every test
setup() {
    if [ -z "$STAGING" ]; then
        export CURL_CA_BUNDLE=/root/pebble-ca-bundle.crt
    fi
}


@test "Use PREFERRED_CHAIN to select an alternate root" {
    if [ -n "$STAGING" ]; then
        PREFERRED_CHAIN="Fake LE Root X2"
    else
        PREFERRED_CHAIN=$(curl --silent https://pebble:15000/roots/2 | openssl x509 -text -noout | grep "Issuer:" | cut -d= -f2)
        PREFERRED_CHAIN="${PREFERRED_CHAIN# }" # remove leading whitespace
    fi

    CONFIG_FILE="getssl-dns01.cfg"
    setup_environment
    init_getssl

    cat <<- EOF > ${INSTALL_DIR}/.getssl/${GETSSL_CMD_HOST}/getssl_test_specific.cfg
PREFERRED_CHAIN="${PREFERRED_CHAIN}"
EOF

    create_certificate
    assert_success
    check_output_for_errors

    issuer=$(openssl crl2pkcs7 -nocrl -certfile "${INSTALL_DIR}/.getssl/${GETSSL_CMD_HOST}/fullchain.crt" | openssl pkcs7 -print_certs -text -noout | grep Issuer: | tail -1 | cut -d= -f2)
    # verify certificate is issued by preferred chain root
    [ "$PREFERRED_CHAIN" = "$issuer" ]
}


@test "Use PREFERRED_CHAIN to select the default root" {
    if [ -n "$STAGING" ]; then
        PREFERRED_CHAIN="Fake LE Root X1"
    else
        PREFERRED_CHAIN=$(curl --silent https://pebble:15000/roots/0 | openssl x509 -text -noout | grep Issuer: | cut -d= -f2 )
        PREFERRED_CHAIN="${PREFERRED_CHAIN# }" # remove leading whitespace
    fi

    CONFIG_FILE="getssl-dns01.cfg"
    setup_environment
    init_getssl

    cat <<- EOF > ${INSTALL_DIR}/.getssl/${GETSSL_CMD_HOST}/getssl_test_specific.cfg
PREFERRED_CHAIN="${PREFERRED_CHAIN}"
EOF

    create_certificate
    assert_success
    check_output_for_errors

    issuer=$(openssl crl2pkcs7 -nocrl -certfile "${INSTALL_DIR}/.getssl/${GETSSL_CMD_HOST}/fullchain.crt" | openssl pkcs7 -print_certs -text -noout | grep Issuer: | tail -1 | cut -d= -f2)
    # verify certificate is issued by preferred chain root
    [ "$PREFERRED_CHAIN" = "$issuer" ]
}


@test "Use PREFERRED_CHAIN to select an alternate root by suffix" {
    if [ -n "$STAGING" ]; then
        FULL_PREFERRED_CHAIN="Fake LE Root X2"
    else
        FULL_PREFERRED_CHAIN=$(curl --silent https://pebble:15000/roots/2 | openssl x509 -text -noout | grep "Issuer:" | cut -d= -f2)
        FULL_PREFERRED_CHAIN="${FULL_PREFERRED_CHAIN# }" # remove leading whitespace
    fi

    # Take the last word from FULL_PREFERRED_CHAIN as the chain to use
    PREFERRED_CHAIN="${FULL_PREFERRED_CHAIN##* }"
    CONFIG_FILE="getssl-dns01.cfg"
    setup_environment
    init_getssl

    cat <<- EOF > ${INSTALL_DIR}/.getssl/${GETSSL_CMD_HOST}/getssl_test_specific.cfg
PREFERRED_CHAIN="${PREFERRED_CHAIN}"
EOF

    create_certificate
    assert_success
    check_output_for_errors

    issuer=$(openssl crl2pkcs7 -nocrl -certfile "${INSTALL_DIR}/.getssl/${GETSSL_CMD_HOST}/fullchain.crt" | openssl pkcs7 -print_certs -text -noout | grep Issuer: | tail -1 | cut -d= -f2)
    # verify certificate is issued by preferred chain root
    echo "# ${issuer}"
    echo "# ${FULL_PREFERRED_CHAIN}"
    [ "$FULL_PREFERRED_CHAIN" = "$issuer" ]
}
