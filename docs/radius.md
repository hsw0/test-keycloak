# RADIUS

## DB 연동

[좀 더 설명 추가]

### 예제: 윈도 연동 없이 로컬 MS-CHAPv2 인증

윈도 서버 연동(Winbind) 없이 DB에 저장된 NT Hash로 MS-CHAPv2 인증하기.
PEAP, EAP-TTLS + CHAP 호환.


* 그룹 등록

DB 계정임을 식별하기 쉽도록 그룹을 만들고, 혹시 `ntlm_auth`가 설정된 경우 무시하도록 `MS-CHAP-Use-NTLM-Auth:=0` 으로 설정 [3]

```sql
INSERT INTO radgroupcheck (groupname, attribute, op, value) VALUES ('database', 'MS-CHAP-Use-NTLM-Auth', ':=', '0');
```

그 외 공통 속성을 넣어도 될 것 같다

* 계정 등록

```sql
INSERT INTO radcheck (username, attribute, op, value) VALUES ('username', 'NT-Password', ':=', '8846f7eaee8fb117ad06bdd830b7586c');
INSERT INTO radusergroup (username, groupname) VALUES ('username', 'database');
```

활용예: 그룹웨어에서 "기기" (PC, 폰, ..) 등록하면 해당 기기 전용 네트워 접속 계정/암호를 발급. 개인 계정 암호가 아니라 기기 계정으로 로그인. PC를 AD에 가입하지 않은 경우 유용할 것 같다.

### NT Hash 알고리즘

문자열을 UTF-16 (Little Endian)으로 인코딩한 후 MD4 해시한 값

ex)

```bash
$ echo -n 'password' | iconv -f UTF-8 -t UTF-16LE | openssl dgst -md4 -hex
(stdin)= 8846f7eaee8fb117ad06bdd830b7586c
```

### NAS(클라이언트) 등록

```sql
INSERT INTO nas (nasname, shortname, secret) VALUES ('172.17.0.0/16', 'test', 'testing123');
```

주의: 클라이언트는 실시간 반영되지 않음. 서버 재시작 필요.

## 테스트

`wpa_supplicant` 패키지의 `eapol_test` 툴을 사용하여 RADIUS 인증 테스트하는 법.

```bash
# yum install wpa_supplicant
```

아래와 같이 테스트 설정 파일을 만든다

`eapol-test.conf`:
```
network={
    key_mgmt=WPA-EAP
    eap=PEAP
    phase2="autheap=MSCHAPV2"
    identity="계정"
    password="암호"
}
```

```bash
$ eapol-test -c eapol-test.conf [-a RADIUS서버] [-p RADIUS포트] -s RADIUS-SHARED-SECRET
```

```bash
$ eapol-test -c eapol-test.conf -s testing123
```

* See also:
    - [man 8 eapol_test](https://www.unix.com/man-page/centos/8/eapol_test/)
    - [man 5 wpa_supplicant.conf](https://linux.die.net/man/5/wpa_supplicant.conf)


___

References:

1. [Wiki: "SQL HOWTO"](https://wiki.freeradius.org/guide/SQL-HOWTO)
2. [Wiki: "FreeRADIUS Active Directory Integration HOWTO"](https://wiki.freeradius.org/guide/FreeRADIUS-Active-Directory-Integration-HOWTO)
3. [rlm_mschap](https://github.com/FreeRADIUS/freeradius-server/blob/release_3_0_16/doc/modules/mschap.rst)
