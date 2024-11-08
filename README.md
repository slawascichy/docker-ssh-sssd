# docker-ssh-sssd

## Praca z kontenerem

### Konfiguracja `sudo`

W kontenerze zawarta jest domyślna konfiguracja w pliku `/etc/sudoers.conf`.
Domyślne ustawienia pozwalają na wykonanie operacji sudo dla następujących jednostek:
 - Użytkownicy
 
 ```text
# User privilege specification
root    ALL=(ALL:ALL) ALL
 ```

 - Grupy

 ```text
# Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL

# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL
 ```

Autorytatywnie uznano, że ta konfiguracja wystarczy. Wiedząc o tym wystarczy LDAP utworzyć grupy o nazwie `admin` lub `sudo` i dodać do nich użytkowników mających posiadać takie uprawnienie do nich. Przykładowa konfiguracja grupy `admin`:

![Przykładowa konfiguracja grupy](https://raw.githubusercontent.com/slawascichy/docker-ssh-sssd/refs/heads/main/doc/sample_group_admin.png)


### Tworzenie użytkowników pod `sssd`

Aby wszystko działo jak na leży pamiętać o tym, że powinien on mieć ustawione odpowiednie atrybuty. Poniżej opis najważniejszych z nich:
 - uid - nazwa użytkownika w systemie Unix
 - uidNumber - identyfikator użytkownika w systemie Unix (Unix ID) - ***identyfikator powinien być dla użytkowników unikalny w całym systemie. Jeżeli tego nie zagwarantujesz użytkownicy będą mieli te same uprawnienia prywatne*** Aby zapewnić unikalność niektórzy tworzą pomocniczą entry w drzewie LDAP, w której wartość atrybutu uidNumber wskazuje na ostatnio wykorzystaną wartość i jest aktualizowana po każdym nowym dodaniu entry użytkownika np.:

![Przykładowa UnixIdSequence](https://raw.githubusercontent.com/slawascichy/docker-ssh-sssd/refs/heads/main/doc/sample_entry_UnixIdSequence.png) 

 - gidNumber - identyfikator domyślnej grupy w systemie Unix
 - homeDirectory - nazwa katalogu domowego
 - loginShell - program shell np. `/bin/bash`
 - userPassword - hasło użytkownika
 
Poniżej przykładowe entry użytkownika:

![Przykładowy użytkownik](https://raw.githubusercontent.com/slawascichy/docker-ssh-sssd/refs/heads/main/doc/sample_user.png) 

### Tworzenie grupy pod `sssd`

Grupa powinna mieć następujące atrybuty. Poniżej opis najważniejszych z nich:
 - cn - nazwa grupy w systemie Unix
 - gidNumber - identyfikator grupy w systemie Unix - ***identyfikator powinien być dla grup unikalny w całym systemie. Jeżeli tego nie zagwarantujesz użytkownicy będą mieli te same role/uprawnienia grup*** - zobacz opisany problem w części poświęconej użytkownikom.

### Połączenie się po SSH:

```shell
ssh -p 8022 scichy@localhost
```


## Obsługa kontenera
 
### Budowanie obrazu kontenera:

Poniżej opis budowania obrazu kontenera.

---
**UWAGA**
Jeżeli chcesz skonfigurować SSL pod komunikację z serwerem LDAP, to wrzuć odpowiednie podpisane certyfikaty z rozszerzeniem pliku `*.pem` do katalogu `assets/cacerts` - zobacz przykładowe pliki z certyfikatami CA firmy IBPM S.A.
---

```shell
docker build -f Dockerfile --no-cache -t ibpm/sssd:ubuntu-0.1 .
```

Uruchamianie kontenera z parametrami definiującymi komunikację z LDAP:

```shell
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

Poniżej opis obsługi kompozycji.

> [!IMPORTANT]
> **UWAGA**
> Aby skorzystać z kompozycji trzeba wpierw zbudować obraz (image) dla kontenera oraz trzeba przygotować katalog dla wolumenu np. w Windows katalog `D:\mercury\sss` aby mógł być zdefiniowany jako device: `/d/mercury/sss`.

Można uruchomić kompozycję (definicja kompozycji jest w pliku `docker-compose.yml`. Wystarczy tylko ustawić prawidłowe parametry w pliku `sssd-conf.env` (***UWAGA***: Nie ma go?! To utwórz własny plik konfiguracyjny dla kompozycji!) np.

```text
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

```shell
docker compose --env-file sssd-conf.env up
```

## Uruchomienie kompozycji z openLdap

> [!IMPORTANT]
> **UWAGA**
> Wpierw ściągnij projekt [docker-openldap](https://github.com/slawascichy/docker-openldap) i zbuduj sobie obraz z serwerem OpenLDAP.

W projekcie są 2 przykładowe pliki dla kompozycji klienta sssd oraz serwera OpenLDAP:
1. docker-compose-with-openldap.yml - plik z definicją kompozycji
2. sssd-openldap-conf.env - plik z parametrami kompozycji

Poniżej polecenie budowania kompozycji:

```shell
docker compose --file docker-compose-with-openldap.yml --env-file sssd-openldap-conf.env up
```

Wpisami LDAP zarządzać można za pomocą oprogramowania [Apache Directory Studio RCP Application](https://directory.apache.org/studio/downloads.html).
Jeżeli użyjemy niezmienionych parametrów z pliku `sssd-openldap-conf.env` to:
 - URL dostępu do ldap: `ldap://localhost:389/`
 - Bind DN: `uid=ldapui,ou=Admins,dc=scisoftware,dc=pl`
 - Bind password: `secret`

## Uruchomienie kompozycji z openLdap oraz ldap-ui

> [!IMPORTANT]
> **UWAGA**
> Wpierw ściągnij projekt [docker-openldap](https://github.com/slawascichy/docker-openldap) i zbuduj sobie obraz z serwerem OpenLDAP.

Chłopaki odwalili kawał dobrej roboty pisząc UI dla LDAP'a. Oprogramowanie dostępne jest na podstawie licencji MIT, więc można korzystać do woli. Repozytorium kodów źródłowych: [ldap-ui](https://github.com/dnknth/ldap-ui).

![Przykładowy użytkownik](https://raw.githubusercontent.com/slawascichy/docker-ssh-sssd/refs/heads/main/doc/ldap-ui.png) 

W projekcie są 2 przykładowe pliki dla kompozycji klienta sssd, serwera OpenLDAP oraz ldap-ui :
1. docker-compose-with-openldap-ldapui.yml - plik z definicją kompozycji
2. sssd-openldap-conf.env - plik z parametrami kompozycji

Poniżej polecenie budowania kompozycji: 

```
docker compose --file docker-compose-with-openldap.yml --env-file sssd-openldap-conf.env up
```
Wpisami LDAP zarządzać można teraz za pomocą aplikacji WWW.
Jeżeli użyjemy niezmienionych parametrów z pliku `sssd-openldap-conf.env` to:
 - URL dostępu do UI: `http://localhost:5000/`
 - Uwierzytelnianie Basic, nazwa użytkownika: `ldapui`, hasło: `secret`

> [!CAUTION]
>**UWAGA**
>Dostęp bezpośrednio do serwera LDAP nie jest możliwy - korzystać z niego mogą tylko kontenery.

## Znane problemy

Na razie nie wykryto nowych, a dotychczasowe rozwiązano.
