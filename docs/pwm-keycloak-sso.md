# PWM + Keycloak SSO

PWM 의 OAuth SSO 기능을 사용하여 Keycloak과 연동 가능하다.


작동은 하지만 권장하지 않는다.
* Workaround가 별로 마음에 안든다
* 설정시 무조건 SSO로만 동작한다. SSO에 문제 발생시 로그인 불가.
* 자주 보지도 않을 암호 변경 페이지에 굳이 SSO를 해야 되나?

## Keycloak 클라이언트 등록

* Settings
    - Client ID: pwm (또는 아무거나)
    - Client Type: `openid-connect`
    - Access Type: `confidential`
    - Standard Flow Enabled: ON
    - Root URL: `https://pwm.example.com`
    - Valid Redirect URIs:
         * `/public/oauth`
* Credentials
    - Client Authenticator: `Client Id and Secret`
    - Secret: 잘 메모

## PWM 설정

설정 위치: Settings ⇨ Single Sign On (SSO) Client ⇨ OAuth

* OAuth Client ID: pwm (Keycloak에서 등록한 값)
* OAuth Shared Secret: Keycloak에서 발급한 Secret
* OAuth User Name/DN Login Attribute: `preferred_username`
    - Keycloak 클라이언트 설정 > Mapper에서 등록한 값.
    - 주의: Name 이 아니라 **Token Claim Name** 를 사용함

* OAuth Login URL: `https://keycloak.example.com/auth/realms/example/protocol/openid-connect/auth`
* OAuth Code Resolve Service URL: `https://keycloak.example.com/auth/realms/example/protocol/openid-connect/token`
* OAuth Profile Service URL: `https://keycloak.example.com/auth/realms/example/protocol/openid-connect/userinfo`
* 위 URL 들은 OpenID Discovery Endpoint (/auth/realms/example/.well-known/openid-configuration) 에서 확인 가능

* OAUTH Web Service Server Certificate: Import 버튼 클릭


## 이슈

OAuth2 플로우 마지막에서 Profile Service URL로 사용자 정보를 조회할 때 Authorization 헤더로 방금 발급한 Access Token이 아닌 PWM 클라이언트 ID:Secret로 인증을 시도한다. (Access Token은 Body로 전송)
Keycloak에서 이걸 거부하여 PWM에서 아래와 같은 오류가 발생한다

```
FATAL, servlet.AbstractPwmServlet, {33} unexpected error: 5071 ERROR_OAUTH_ERROR (unexpected HTTP status code (401) during OAuth getattribute request to https://keycloak.example.com/
auth/realms/example/protocol/openid-connect/userinfo)
```


## Workaround

전지전능한 nginx 설정을 활용하여 Userinfo endpoint URL을 PWM Client ID로 Basic 인증 헤더를 달고 호출하는 경우 Keycloak로 프록시 하기 전에 인증 헤더를 지워버리면 된다.

`/etc/nginx/conf.d/keycloak.conf`:


```
set $auth_header "$http_authorization";
set $clear_auth_header_cond "$request_uri\n$remote_user";
if ($clear_auth_header_cond = "/auth/realms/example/protocol/openid-connect/userinfo\npwm") {
    set $auth_header "";
}
proxy_set_header "Authorization" "$auth_header";
```

