# Keycloak + 기타 테스트

[공식 문서](http://www.keycloak.org/documentation.html)


## 정리

### 잘 되는거

* Active Directory 사용자 연동
   - 계정/그룹 동기화
   - 암호 변경
   - LDAP / Kerberos 인증

* Google 사용자 인증 (및 그 외 Open ID connect)
   - 별도 인증 플로우 설정시 사용자/암호/IdP 선택 폼 없이 바로 인증 가능
   - 별도 인증 플로우 설정시 특정 Google Apps 도메인 사용자만 허용 가능
   - 이메일이 같은 기존 계정이 있을 경우 암호 인증 후 자동으로 IdP 연동

### 이슈
   - Keycloak User Groups Retrieve Strategy 중 `LOAD_GROUPS_BY_MEMBER_ATTRIBUTE_RECURSIVELY` 는 예제로 설정한 Samba 4.3에서 제대로 작동하지 않음 [이슈](https://bugzilla.samba.org/show_bug.cgi?id=10493)


## 로컬 설정

/etc/hosts:

```
192.168.33.220	keycloak.example.com ci.example.com
```

## Keycloak 설정

* URL: https://keycloak.example.com

### 관리 realm: master (기본값)

* 관리 콘솔: https://keycloak.example.com/admin/master/console

* Login: admin
* Password: admin

### 주 realm: example

계정 관리 페이지: https://keycloak.example.com/realms/example/account

## Samba 4 AD 설정

* Domain: EXAMPLE.COM
* Login: Administrator
* Password: admin

필요할 경우 아래 명령으로 셸 진입

```
docker exec -ti samba-dc /bin/bash -l
```

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
