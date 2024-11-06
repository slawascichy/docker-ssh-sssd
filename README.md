# docker-ssh-sssd

## Obsługa kontenera
 
### Budowanie obrazu kontenera:

```
docker build -f Dockerfile --no-cache -t ibpm/sssd:ubuntu-0.1 .
```

Uruchamianie kontenera z parametrami definiującymi komunikację z LDAP:

```
docker run -d -p 8022:22 --name sssd \
 -e LDAP_URI="ldaps://auth-1.ibpm.pro:9636" \
 -e LDAP_SEARCH_BASE="dc=ibpm,dc=pro" \
 -e LDAP_USER_SEARCH_BASE="ou=Users,ou=ibpm.pro,dc=ibpm,dc=pro" \
 -e LDAP_ACCESS_FILTER="(&(objectclass=shadowaccount)(objectclass=posixaccount)(allowSystem=front-001.ibpmpro.srv;shell;*))" \
 -e LDAP_GROUP_SEARCH_BASE="ou=Groups,ou=ibpm.pro,dc=ibpm,dc=pro" \
 -e LDAP_GROUP_MEMBER="uniqueMember" \
 -e LDAP_BIND_DN="cn=Manager,dc=ibpm,dc=pro" \
 -e LDAP_BIND_PASSWORD="secret" \
 -v /var/lib/sss \
 ibpm/sssd:ubuntu-0.1
```

### Obsługa kompozycji

Uwaga! Aby skorzystać z kompozycji trzeb wpierw zbudować obraz (image) dla kontenera oraz trzeba przygotować katalog dla wolumenu np. w Windows katalog `D:\mercury\sss` aby mógł być zdefiniowany jako device: `/d/mercury/sss`.

Można uruchomić kompozycję (definicja kompozycji jest w pliku `docker-compose.yml`. Wystarczy tylko ustawić prawidłowe parametry w pliku `sssd-conf.env`. Kompozycję uruchamiamy za pomocą polecenia:

```
docker compose --env-file sssd-conf.env up
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
