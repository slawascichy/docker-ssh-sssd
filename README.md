# docker-ssh-sssd

## Obsługa kontenera
 
### Budowanie obrazu kontenera:

---
**UWAGA**
Jeżeli chcesz skonfigurować SSL pod komunikację z serwerem LDAP, to wrzuć odpowiednie podpisane certyfikaty z rozszerzeniem pliku `*.pem` do katalogu `assets/cacerts` - zobacz przykładowe pliki z certyfikatami CA firmy IBPM S.A.
---

```
docker build -f Dockerfile --no-cache -t ibpm/sssd:ubuntu-0.1 .
```

Uruchamianie kontenera z parametrami definiującymi komunikację z LDAP:

```
docker run -d -p 8022:22 --name sssd \
 -e LDAP_URI="ldaps://<server_name>:<port>" \
 -e LDAP_USE_TSL=True
 -e LDAP_SEARCH_BASE="dc=example,dc=com" \
 -e LDAP_USER_SEARCH_BASE="ou=Users,ou=example.com,dc=example,dc=com" \
 -e LDAP_ACCESS_FILTER="(&(objectclass=shadowaccount)(objectclass=posixaccount)(allowSystem=front-001.example.com;shell;*))" \
 -e LDAP_GROUP_SEARCH_BASE="ou=Groups,ou=example.com,dc=example,dc=com" \
 -e LDAP_GROUP_MEMBER="uniqueMember" \
 -e LDAP_BIND_DN="cn=Manager,dc=example,dc=com" \
 -e LDAP_BIND_PASSWORD="secret" \
 -v /var/lib/sss \
 ibpm/sssd:ubuntu-0.1
```

### Obsługa kompozycji

---
**UWAGA**
Aby skorzystać z kompozycji trzeba wpierw zbudować obraz (image) dla kontenera oraz trzeba przygotować katalog dla wolumenu np. w Windows katalog `D:\mercury\sss` aby mógł być zdefiniowany jako device: `/d/mercury/sss`.
---

Można uruchomić kompozycję (definicja kompozycji jest w pliku `docker-compose.yml`. Wystarczy tylko ustawić prawidłowe parametry w pliku `sssd-conf.env` (***UWAGA***: Nie ma go?! To utwórz własny plik konfiguracyjny dla kompozycji!) np.

```
LDAP_URI=ldaps://<server_name>:<port>
LDAP_USE_TSL=True
LDAP_SEARCH_BASE=dc=example,dc=com
LDAP_USER_SEARCH_BASE=ou=Users,ou=example.com,dc=example,dc=com
LDAP_ACCESS_FILTER=(&(objectclass=shadowaccount)(objectclass=posixaccount)(allowSystem=front-001.example.com;shell;*))
LDAP_GROUP_SEARCH_BASE=ou=Groups,ou=example.com,dc=example,dc=com
LDAP_GROUP_MEMBER=uniqueMember
LDAP_BIND_DN=cn=Manager,dc=example,dc=com
LDAP_BIND_PASSWORD=secret
```

Gdy mamy już gotowy plik (o nazwie `sssd-conf.env`) z parametrami to kompozycję uruchamiamy za pomocą polecenia:

```
docker compose --env-file sssd-conf.env up
```

## Uruchomienie kompozycji z openLdap

---
**UWAGA**
Wpierw ściągnij projekt https://github.com/slawascichy/docker-openldap i zbuduj sobie obraz z serwerem OpenLDAP.
---

W projekcie są 2 przykładowe pliki dla kompozycji z serwerem OpenLDAP oraz klientem sssd:
1. docker-compose-with-openldap.yml - plik z definicją kompozycji
2. sssd-openldap-conf.env - plik z parametrami kompozycji

```
docker compose --file docker-compose-with-openldap.yml --env-file sssd-openldap-conf.env up
```


## Połączenie się po SSH:

```
ssh -p 8022 scichy@localhost
```

## Znane problemy
1. Na razie nie rozwiązano problemu automatycznego tworzenia katalogu użytkownika. Na razie może to zrobić ręcznie sam użytkownik, poprzez wydanie polecenia zaraz po zalogowaniu się do kontenera:

```
mkdir ~
```
