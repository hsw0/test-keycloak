# Keycloak + 기타 테스트

[공식 문서](http://www.keycloak.org/documentation.html)


## 정리

### 잘 되는거

* Active Directory 사용자 연동
   - 계정/그룹 동기화
      - Keycloak에서 계정 삭제시 LDAP에 반영. 그룹 삭제는 반영되지 않음
   - 암호 변경
   - LDAP / Kerberos 인증

* Google 사용자 인증 (및 그 외 Open ID connect)
   - 별도 인증 플로우 설정시 사용자/암호/IdP 선택 폼 없이 바로 인증 가능
   - 별도 인증 플로우 설정시 특정 Google Apps 도메인 사용자만 허용 가능
   - 이메일이 같은 기존 계정이 있을 경우 암호 인증 후 자동으로 IdP 연동

### 안 해본 거
   * 메일 발송
   * TODO: Keycloak LDAP bind 계정 Administrator -> 서비스 계정으로 변경
   * [Keycloak Security Proxy](https://keycloak.gitbooks.io/server-installation-and-configuration/content/v/2.2/topics/proxy.html)
      - Reverse proxy
      - 기존 애플리케이션 수정 없이 인증 붙일 수 있는 것 같다


### 이슈
   - 프로비저닝 실패
       - 네트워크, 타이밍 등 각종 이슈로 가끔 프로비저닝이 실패할 때가 있음. `vagrant provision VM명` 으로 재시도 하거나 날리고 새로 만들것.
   - Keycloak User Groups Retrieve Strategy 중 `LOAD_GROUPS_BY_MEMBER_ATTRIBUTE_RECURSIVELY` 는 예제로 설정한 Samba 4.3에서 제대로 작동하지 않음 [이슈](https://bugzilla.samba.org/show_bug.cgi?id=10493)


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
# ex) vagrant ssh keycloak
```

/etc/hosts:

```
192.168.33.224	dc1.example.com
192.168.33.225	keycloak.example.com
192.168.33.226	ci.example.com
```

## Keycloak 설정

* Vagrant VM: `keycloak`

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

## 기타

### Export/Import:

[Server Administration Guide. Ch 16. Export and Import](https://keycloak.gitbooks.io/server-adminstration-guide/content/topics/export-import.html) 참조

```
/srv/keycloak/bin/standalone.sh  -Dkeycloak.migration.action=export -Dkeycloak.migration.realmName=example -Dkeycloak.migration.provider=dir -Dkeycloak.migration.dir=/vagrant/shared/export
```


___

* [Keycloak](http://www.keycloak.org/)
