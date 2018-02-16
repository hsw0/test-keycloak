# Keycloak + Other tests

## [What is Keycloak?](http://www.keycloak.org/about.html)

[IdM](https://en.wikipedia.org/wiki/Identity_management) and SSO server solutions

* [Website](https://www.keycloak.org)
* [Official documentation](http://www.keycloak.org/documentation.html)

## Please note

The following information are based on the basic management tools without any customization. There may be areas that we have not been able to check.

### Key Concepts

No further explanation is required

* Realm
* [Role](http://www.keycloak.org/docs/latest/server_admin/index.html#roles)
* [Client](http://www.keycloak.org/docs/latest/server_admin/index.html#_clients): An object (service) that can require Keycloak to authenticate the user. Can be linked with SAML / OpenID Connect
* [Identity Brokering / Identity Providers](http://www.keycloak.org/docs/latest/server_admin/index.html#_identity_broker) (IdP): External authentication services such as Google and Facebook
* [User Storage Federation](http://www.keycloak.org/docs/latest/server_admin/index.html#_user-storage-federation): External user DB such as LDAP


### Customization

* Identifier: UUID (immutable)
* Username (aka User ID)
* Password
    - Temporary password: Force change when logging on
* Email
    - Email verification or not
* Last Name / First Name
* Additional attributes
    - Any key-value value.
* Group
* Role
* Creation date and time
* Account lockout settings
* Temporary lock setting (due to login failure)
* OTP
* Actions to force after login
    - OTP Settings
    - Change profile
    - Change Password
    - Email verification
* IdP Integration
    - IDP Side User identifier
    - Token!
* Linked Service
* Login Session


### Access Control

* There is no ability to restrict which services (SAML/OpenID client) can be accessed by user/group.
* Should be controlled with user information received from the service side.
    - Group, Role, Access policy (OpenID only), additional attributes, etc.

### Audit Log

* User Login related/administrator acts are recorded in a structured form with detailed information.
* Of course, there is no action left after each service.

### Active Directory Integration

* LDAP -> Keycloak synchronization:
    1. Imported automatically on first login
    2. Full / incremental synchronization is performed manually or periodically on the console

* Keycloak -> LDAP synchronization:
    - Account creation, modification, and deletion are reflected in LDAP.
        - Self service!
    - Deletion of group is not reflected

* Keycloak also reflects AD when changing password.

* Authentication method:
    - LDAP binding
    - Kerberos/SPNEGO SSO (unconfirmed)
    - Kerberos (Form ID/PW)

### Google user authentication (and other Open ID Connect)

* Accounts with the same email will automatically be associated after the AD password verification. Both Id/password or IdP mode both can used to log in.
* Create an AD account by specifying the ID, mail, last name, and password for the first login
    - No validation option for form input.
    - You can preset or deny a value in a script
* Multiple IDPs can work together
* Authentication flow can be authenticated directly without user/password/IDP selection form
* Only specific Google Apps domain users are allowed in the script
    1. import attribute hd with IdP Attribute Importer.
       Note: This is only required if you are creating a new account with an IdP login.
    2. Comparing the properties imported from a script to 1

### Multi factor authentication

* [HOTP](https://tools.ietf.org/html/rfc4226) - Counter/Time mode support
    - hash algorithm, various parameters can be set
    - Works well in Google authenticator
* OTP can be enforced regardless of authentication method

### Script-based Authentication

* You can set the rules for allowing / denying authentication with JS. See [Java ScriptEngine](https://docs.oracle.com/javase/7/docs/api/javax/script/ScriptEngine.html)
* But very difficult to use (especially for debugging)
* Example: see [snippets/StripEmailDomainFromUsername.js](snippets/StripEmailDomainFromUsername.js).
* Upon denyed, the error message cannot be selected directly, and you must choose from a few constants (http://www.keycloak.org/docs-api/3.4/javadocs/org/keycloak/authentication/AuthenticationFlowError.html)
* Access to this service should not be denied. Only the authentication process flow can be customized, and the flow to the service can not be customized.

### UI Customization

* Provides themes, localization features, etc.
    - except Korean
* In the management tool, the part that can be changed is the title at the top of the login page.
* There are terms and conditions, but no edit page.

### I have not tried it.

* Send mail
    - Check your email address
    - Forgot Password
* OpenID Connect Client AuthZ feature
    - Permission can be set by URL path
* Clustering
* TODO: Keycloak LDAP bind account Administrator-> change to service account
* [Keycloak Security Proxy](http://www.keycloak.org/docs/latest/server_installation/index.html#_setting-up-a-load-balancer-or-proxy)
    - Reverse proxy
    - The existing application seems to be able to be attached without modification
* Kerberos/SPNEGO SSO


### Issue

* Administrator login is released very quickly

* `LOAD_GROUPS_BY_MEMBER_ATTRIBUTE_RECURSIVELY` of Keycloak User Groups Retrieve Strategy does not work properly with Samba 4.3 set as example [Issue] (https://bugzilla.samba.org/show_bug.cgi?id=10493)

* Provisioning Failure
    - Provisioning sometimes fails due to various issues such as network and timing. Try to reprovision the VM using vagrant, or create a new one.
* Problems connecting to VM with SSH key in Vagrant 1.8.5 [vagrant issue #7610](https://github.com/mitchellh/vagrant/pull/7611)
    - [patch](https://github.com/mitchellh/vagrant/pull/7611/files#diff-13c7ed80ab881de1369e3b06c66745e8R57) for `/opt/vagrant/embedded/gems/gems/vagrant-1.8.5/plugins/guests/linux/cap/public_key.rb`


## Local setting

Vagrant installation:

```
brew cask install vagrant
```

Launch:

```
vagrant up
```

VM Shell Entry

```
vagrant ssh VMNAME
# ex) vagrant ssh keycloak
```

/etc/hosts:

```
192.168.33.224	dc1.example.com
192.168.33.225	keycloak.example.com
192.168.33.226	ci.example.com
```

## Keycloak settings

* Vagrant VM: `keycloak`

* URL: https://keycloak.example.com

### Management realm: master (default)

* Admin console: https://keycloak.example.com/admin/master/console

* Login: admin
* Password: admin

### Week realm: example

Account management page: https://keycloak.example.com/realms/example/account

## Samba 4 AD settings

* Vagrant VM: `dc1`

* Domain: EXAMPLE.COM
* Login: Administrator
* Password: admin


### Test Account List

* `hsw@syscall.io` / `test`
* `test1@example.com` / `test`
* `test2@example.com` / `test`

## Integration example: Jenkins

* URL: https://ci.example.com

* [SAML Plugin](https://wiki.jenkins-ci.org/display/JENKINS/SAML+Plugin)
* Grant permissions for each group with Jenkins' own settings

## Etc

### Export/Import:

From [Server Administration Guide. Ch 16. Export and Import](http://www.keycloak.org/docs/latest/server_admin/index.html#_export_import)

```
/srv/keycloak/bin/standalone.sh  -Dkeycloak.migration.action=export -Dkeycloak.migration.realmName=example -Dkeycloak.migration.provider=dir -Dkeycloak.migration.dir=/vagrant/shared/export
```


___

* [Keycloak](http://www.keycloak.org/)
