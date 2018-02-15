# Keycloak + 기타 테스트

## [Keycloak이란?](http://www.keycloak.org/about.html)

[IdM](https://en.wikipedia.org/wiki/Identity_management) 및 SSO 서버 솔루션

* [웹사이트](https://www.keycloak.org)
* [공식 문서](http://www.keycloak.org/documentation.html)

## 정리

아래 내용은 커스터마이징 없이 기본 관리툴 기능만 활용한 것입니다. 미처 확인하지 못한 부분이 있을 수 있습니다.

### 주요 개념

자세한 설명은 생략합니다

* Realm
* [Role](https://keycloak.gitbooks.io/server-adminstration-guide/content/topics/roles.html)
* [클라이언트](https://keycloak.gitbooks.io/server-adminstration-guide/content/topics/clients.html): Keycloak에 사용자 인증을 요구할 수 있는 개체 (서비스). SAML / OpenID Connect 로 연동 가능
* [Identity Brokering / Identity Providers](https://keycloak.gitbooks.io/server-adminstration-guide/content/topics/identity-broker.html) (이하 IdP): Google, Facebook 등 외부 인증 서비스
* [User Storage Federation](https://keycloak.gitbooks.io/server-adminstration-guide/content/topics/user-federation.html): LDAP 등 외부 사용자 DB


### 사용자 설정

* 식별자: UUID (변경불가)
* Username (aka User ID)
* Password
    - 임시 암호: 설정할 경우 로그인시 강제 변경
* 이메일
    - 이메일 검증 여부
* 성 / 이름
* 부가 속성
    - 임의 Key-Value 값.
* 그룹
* Role
* 생성일시
* 계정 잠금 설정
* 임시 잠금 설정 (로그인 실패에 의한)
* OTP
* 로그인 후 강제로 할 행동
    - OTP 설정
    - 프로필 변경
    - 암호 변경
    - 이메일 검증
* 연동한 IdP
    - IdP측 사용자 식별자
    - 토큰!!
* 연동한 서비스
* 로그인 세션


### 접근 제어

* 사용자/그룹 별로 접근 가능한 서비스 (SAML/OpenID 클라이언트) 를 제한하는 기능은 없다.
* 서비스측에서 받은 사용자 정보로 제어해야 한다.
    - 그룹, Role, 접근 정책(OpenID 전용), 부가 속성 등

### 감사 로그

* 사용자 "로그인 관련" / 관리자 행위별로 자세한 정보와 함께 구조화된 형태로 기록된다.
* 당연하지만 각 서비스로 넘어간 뒤 행위는 남지 않는다.

### Active Directory 연동

* LDAP -> Keycloak 동기화:
    1. 최초 로그인시 자동으로 가져옴
    2. 전체 / 증분 동기화는 콘솔에서 수동으로 또는 정기적으로 수행

* Keycloak -> LDAP 동기화:
    - 계정 생성, 수정, 삭제시 LDAP에 반영.
        - Self service!
    - 그룹 삭제는 반영되지 않음

* Keycloak에서 암호 변경시 AD에도 반영.

* 인증 방식:
    - LDAP binding
    - Kerberos/SPNEGO SSO (미확인)
    - Kerberos (폼 ID/PW)

### Google 사용자 인증 (및 그 외 Open ID connect)

* 이메일이 같은 계정이 있을 경우 AD 암호 확인 후 자동으로 IdP 연동됨. 이후 ID/암호 또는 IdP 방식 둘 다 로그인 가능.
* 첫 로그인시 사용할 ID, 메일, 성,이름, 암호를 지정하면 AD 계정 생성
    - 폼 입력값 검증 옵션이 없음.
    - 스크립트에서 값을 미리 설정하거나 거부할 수는 있음
* 서로 다른 IdP는 여러 개 연동 가능
* 인증 플로우 설정시 사용자/암호/IdP 선택 폼 없이 바로 인증 가능
* 스크립트로 특정 Google Apps 도메인 사용자만 허용 가능
    1. IdP Attribute Importer로 hd 속성 import.
       주의: IdP 로그인으로 계정을 신규 생성하는 경우에만 입력된다.
    2. 스크립트에서 1에서 가져온 속성과 비교

### Multi factor authentication

* [HOTP](https://tools.ietf.org/html/rfc4226) - 카운터/시간 방식 지원
    - 해시 알고리즘, 각종 파라메터 설정 가능
    - Google Authenticator에서 잘 작동
* 인증 방식에 상관 없이 OTP 사용 강제 가능

### Script-based Authentication

* JS로 인증 허용/거부 규칙을 설정할 수 있다. [Java ScriptEngine](https://docs.oracle.com/javase/7/docs/api/javax/script/ScriptEngine.html)을 사용.
* 그런데 사용이 매우 어렵다 (특히 디버깅 등)
* 예제: [snippets/StripEmailDomainFromUsername.js](snippets/StripEmailDomainFromUsername.js) 참조.
* 거부시 오류 메시지는 직접 선택할 수 없고 [상수 몇개](http://www.keycloak.org/docs/javadocs/org/keycloak/authentication/AuthenticationFlowError.html) 중에서 선택해야 한다.
* 이걸로 서비스로 넘어갈 때 접근 거부는 안 된다. 인증 과정 플로우만 커스터마이징 할수 있고 서비스로 넘어가는 플로우는 커스터마이징 자체가 불가능.

### UI 커스터마이징

* 테마, 지역화 기능 등 제공
    - 한국어 빼고
* 관리툴에서 변경 가능한 부분은 로그인 페이지 상단의 타이틀 정도... 경고 배너도 못 넣는다.
* 약관 기능은 있으나 수정 페이지가 없음.

### 안 해본 거

* 메일 발송
    - 메일주소 확인
    - 암호 분실
* OpenID Connect 클라이언트 AuthZ 기능
    - URL path 별로 권한 설정이 가능할 것 같다.
* 클러스터링
* TODO: Keycloak LDAP bind 계정 Administrator -> 서비스 계정으로 변경
* [Keycloak Security Proxy](https://keycloak.gitbooks.io/server-installation-and-configuration/content/v/2.2/topics/proxy.html)
    - Reverse proxy
    - 기존 애플리케이션 수정 없이 인증 붙일 수 있는 것 같다
* Kerberos/SPNEGO SSO


### 이슈

* 관리자 로그인이 매우 빨리 풀린다

* Keycloak User Groups Retrieve Strategy 중 `LOAD_GROUPS_BY_MEMBER_ATTRIBUTE_RECURSIVELY` 는 예제로 설정한 Samba 4.3에서 제대로 작동하지 않음 [이슈](https://bugzilla.samba.org/show_bug.cgi?id=10493)

* 프로비저닝 실패
    - 네트워크, 타이밍 등 각종 이슈로 가끔 프로비저닝이 실패할 때가 있음. `vagrant provision VM명` 으로 재시도 하거나 날리고 새로 만들것.
* Vagrant 1.8.5에서 SSH 키로 VM 접속 문제 [vagrant 이슈 #7610](https://github.com/mitchellh/vagrant/pull/7611)
    - `/opt/vagrant/embedded/gems/gems/vagrant-1.8.5/plugins/guests/linux/cap/public_key.rb` 에 [패치](https://github.com/mitchellh/vagrant/pull/7611/files#diff-13c7ed80ab881de1369e3b06c66745e8R57)


## 로컬 설정

Vagrant 설치:

```
brew cask install vagrant
```

구동:

```
vagrant up
```

VM 셸 진입

```
vagrant ssh VM 명
# ex) vagrant ssh idsvc
```

/etc/hosts:

```
192.168.33.224	dc1.example.com
192.168.33.225	idsvc.example.com keycloak.example.com pwm.example.com
192.168.33.226	ci.example.com
```

## Keycloak 설정

* Vagrant VM: `idsvc`

* URL: https://keycloak.example.com

### 관리 realm: master (기본값)

* 관리 콘솔: https://keycloak.example.com/admin/master/console

* Login: admin
* Password: admin

### 주 realm: example

계정 관리 페이지: https://keycloak.example.com/realms/example/account

## Samba 4 AD 설정

* Vagrant VM: `dc1`

* Domain: EXAMPLE.COM
* Login: Administrator
* Password: admin


### 테스트 계정 목록

* `hsw@syscall.io` / `test`
* `test1@example.com` / `test`
* `test2@example.com` / `test`

## 연동 예제: Jenkins

* URL: https://ci.example.com

* [SAML 플러그인](https://wiki.jenkins-ci.org/display/JENKINS/SAML+Plugin)으로 연동.
* Jenkins 자체 설정으로 그룹별로 권한 부여

## 기타

### Export/Import:

[Server Administration Guide. Ch 16. Export and Import](https://keycloak.gitbooks.io/server-adminstration-guide/content/topics/export-import.html) 참조

```
/srv/keycloak/bin/standalone.sh  -Dkeycloak.migration.action=export -Dkeycloak.migration.realmName=example -Dkeycloak.migration.provider=dir -Dkeycloak.migration.dir=/vagrant/shared/export
```


___

* [Keycloak](http://www.keycloak.org/)
