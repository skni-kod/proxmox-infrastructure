# 🚀 Proxmox Infrastructure

Repozytorium zawierające definicję infrastruktury jako kodu (IaC) dla środowiska Proxmox. Całość jest zarządzana w modelu **GitOps** przy użyciu GitHub Actions, co oznacza, że repozytorium jest jedynym źródłem prawdy (Single Source of Truth), a wdrożenia odbywają się automatycznie poprzez Pull Requesty.

## 🛠️ Architektura i Stack Technologiczny

- **Provisioning (Sprzęt):** Terraform (provider `bpg/proxmox`)
- **Konfiguracja (System/Aplikacje):** Ansible (z wtyczką dynamic inventory `community.proxmox`)
- **Zarządzanie Stanem (Backend):** MinIO
- **CI/CD:** GitHub Actions

## 📂 Struktura Repozytorium

Repozytorium jest podzielone na niezależne komponenty infrastruktury (np. `k8s-cluster`). Każdy komponent zawiera własną warstwę provisioningową (Terraform) oraz konfiguracyjną (Ansible).

```text
proxmox-infrastructure/
├── .github/
│   └── workflows/
│       ├── pr-plan.yml      # Walidacja, Linting i Terraform Plan
│       └── pr-apply.yml     # ChatOps: Wdrażanie po wpisaniu /apply
├── components/
│   └── k8s-cluster/
│       ├── ansible/
│       │   ├── inventory.proxmox.yml  # Dynamic inventory Proxmox
│       │   ├── playbook.yml           # Główny playbook Ansible
│       │   └── requirements.yml       # Zewnętrzne, wersjonowane role
│       └── terraform/
│           ├── main.tf                # Odwołania do zewnętrznych modułów
│           ├── variables.tf           # Deklaracja zmiennych
│           └── *.tfvars               # Jawna konfiguracja (IP, zasoby, nazwy)
└── README.md
```

> **Uwaga:** To repozytorium zarządza kodem środowiska docelowego. Logika modułów i ról jest przechowywana w zewnętrznych, wersjonowanych repozytoriach:
>
> - `terraform-modules`: https://github.com/skni-kod/terraform-modules
> - `ansible-roles`: https://github.com/skni-kod/ansible-roles

## 🔄 Proces Wdrażania Zmian (Workflow GitOps)

Wdrażanie zmian opiera się na procesie Pull Request (PR) z wykorzystaniem mechanizmu ChatOps.

1. **Utworzenie brancha:** Stwórz nową gałąź z najnowszego `main` i wprowadź zmiany (np. zmodyfikuj istniejący komponent lub stwórz nowy).
2. **Otwarcie Pull Requesta:** Wypchnij gałąź na GitHuba i otwórz PR.
3. **Automatyczna Walidacja (CI):** Potok `pr-plan.yml` uruchomi się automatycznie:
   - Zwaliduje kod Terraforma.
   - Sprawdzi składnię Ansible (`ansible-lint`).
   - Wygeneruje i wyświetli `terraform plan`.
4. **Wdrożenie (ChatOps):** Jeśli akceptujesz wygenerowany plan, dodaj w Pull Requeście komentarz o treści:
   ```text
   /apply
   ```
   **Realizacja (CD):** Potok pr-apply.yml przechwyci komendę, wdroży infrastrukturę (terraform apply), skonfiguruje maszyny (ansible-playbook) i automatycznie zamknie (zmerguje) Pull Request.

## 🏗️ Część sprzętowa (Terraform)

Katalog `terraform/` wewnątrz każdego komponentu (np. `components/k8s-cluster/terraform/`) odpowiada za tzw. provisioning, czyli powoływanie do życia czystej infrastruktury wirtualnej w Proxmoxie (np. maszyny wirtualne czy kontenery). Terraform działa w pełni deklaratywnie, definiując docelowy kształt środowiska.

Kluczowe elementy architektury sprzętowej:

- **Zarządzanie Stanem w chmurze (MinIO / S3):**
  Plik `.tfstate` nigdy nie jest przetrzymywany w repozytorium (jest ignorowany przez Git). Zamiast tego, jest bezpiecznie przechowywany na serwerze MinIO. Zapewnia to bezpieczną pracę potoków CI/CD i eliminuje ryzyko konfliktów przy jednoczesnych wdrożeniach.

- **Wykorzystanie modułów (`main.tf`):**
  Główny plik konfiguracyjny nie powiela niskopoziomowego kodu tworzenia maszyn. `main.tf` odwołuje się do zewnętrznych, wersjonowanych modułów (z repozytorium `terraform-modules`), przekazując do nich odpowiednie parametry. Dzięki temu logika tworzenia VM-ek, czy kontenerów jest ujednolicona.

- **Zmienne środowiskowe (`*.tfvars`):**
  To najważniejszy plik z perspektywy inżyniera operującego na klastrze. Przechowuje jawne parametry wdrożenia, takie jak liczba węzłów (`count`), adresacja IP, wielkość dysków czy przydział pamięci.

- **Integracja z Ansible (Tagowanie maszyn):**
  Terraform nie tylko tworzy maszyny, ale również nadaje im odpowiednie metadane i tagi w Proxmoxie (np. `k8s-master`, `k8s-worker`). Jest to kluczowy krok (tzw. "handshake" między narzędziami), ponieważ to właśnie na podstawie tych tagów wtyczka dynamic inventory Ansible wie, jakie role aplikacyjne przypisać do konkretnych maszyn tuż po ich uruchomieniu.

## ⚙️ Część konfiguracyjna (Ansible)

Katalog `ansible/` wewnątrz każdego komponentu (np. `components/k8s-cluster/ansible/`) odpowiada za post-provisioning. Podczas gdy Terraform dostarcza "czysty" sprzęt wirtualny, Ansible konfiguruje systemy operacyjne i instaluje aplikacje (m.in. przygotowanie środowiska).

Kluczowe elementy architektury konfiguracyjnej:

- **Dynamiczny Inwentarz (`inventory.proxmox.yml`):**
  Zamiast statycznej listy adresów IP, projekt korzysta z wtyczki `community.proxmox`. Ansible łączy się z API Proxmoxa i w locie pobiera listę uruchomionych maszyn wirtualnych. Grupowanie węzłów odbywa się na podstawie tagów lub nazw nadanych wcześniej przez Terraforma.

- **Zewnętrzne zależności (`requirements.yml`):**
  Repozytorium `proxmox-infrastructure` nie zawiera samej logiki konfiguracyjnej (tasków). Plik `requirements.yml` definiuje, z jakich zewnętrznych repozytoriów (`ansible-roles`) i w jakich **dokładnych wersjach** (tagach) pobrać konkretne role. Pozwala to na niezależny rozwój ról i bezpieczne, wersjonowane wdrożenia.

- **Orkiestracja (`playbook.yml`):**
  Główny punkt wejścia dla konfiguracji, który mapuje zaimportowane role do odpowiednich grup maszyn wykrytych w dynamicznym inwentarzu.

## ⚡ CI/CD workflows (GitHub Actions)

Infrastruktura jest zarządzana przez dwa główne potoki:

### 1. Walidacja i Planowanie (`pr-plan.yml`)

**Wyzwalacz:** Utworzenie lub aktualizacja (push) w Pull Requeście.
Potok ten jest pierwszą linią obrony. Dba o jakość kodu i bezpieczeństwo wdrożenia, nie wprowadzając jeszcze żadnych zmian w środowisku.

- **Wykrywanie zmian:** Dynamicznie sprawdza, które komponenty infrastruktury (np. folder `components/k8s-cluster`) zostały zmodyfikowane.
- **Linting i Walidacja:** Sprawdza formatowanie Terraforma (`terraform fmt/validate`) oraz jakość kodu Ansible (`ansible-lint`).
- **Planowanie (Terraform Plan):** Generuje podgląd zmian (plan) w infrastrukturze i prezentuje go, dając zespołowi możliwość weryfikacji (Code Review) przed faktycznym wdrożeniem.

### 2. Wdrożenie - ChatOps (`pr-apply.yml`)

**Wyzwalacz:** Dodanie komentarza o treści `/apply` w otwartym Pull Requeście.
Potok ten odpowiada za faktyczną realizację zmian w środowisku Proxmox i jest uruchamiany celowo przez inżyniera po zatwierdzeniu planu.

- **Autoryzacja komendy:** Weryfikuje, czy komentarz to faktyczna komenda wdrożeniowa.
- **Provisioning (Terraform):** Wykonuje `terraform apply -auto-approve`, tworząc lub modyfikując sprzęt wirtualny na Proxmoxie (np. maszyny wirtualne, dyski, sieci).
- **Konfiguracja (Ansible):** Pobiera dynamiczny inwentarz nowo utworzonych maszyn z Proxmoxa i uruchamia `ansible-playbook`, konfigurując systemy operacyjne i aplikacje.
- **Finalizacja:** Po pomyślnym nałożeniu zmian, potok automatycznie scala (merge) gałąź do `main` i usuwa branch tymczasowy, zamykając PR.

## 🔐 Wymagane Sekrety (GitHub Secrets)

Aby środowisko CI/CD mogło poprawnie funkcjonować, w ustawieniach repozytorium (_Settings -> Secrets and variables -> Actions_) muszą być zdefiniowane następujące sekrety:

### 1. Dostęp do węzłów i repozytoriów

- **`SSH_PRIVATE_KEY`** - Klucz prywatny ed25519 używany przez Ansible do logowania na wdrażane maszyny oraz do pobierania prywatnych ról z GitHuba.

### 2. Backend Terraforma (MinIO S3)

- **`MINIO_ACCESS_KEY`** - Identyfikator dostępu do MinIO.
- **`MINIO_SECRET_KEY`** - Tajny klucz do MinIO.

### 3. Autoryzacja Proxmox (Terraform & Ansible)

- **`PROXMOX_API_TOKEN`** - Pełny token API w formacie wymaganym przez Terraforma (np. `user@pve!token=uuid`).
- **`PROXMOX_TOKEN_ID`** - Pierwsza część tokenu (np. `user@pve!token`) wymagana przez wtyczkę Ansible.
- **`PROXMOX_TOKEN_SECRET`** - Druga część tokenu, czyli sam klucz (UUID) wymagany przez wtyczkę Ansible.

## 🛡️ Bezpieczeństwo i Dobre Praktyki

- **Pliki stanu:** Pliki `*.tfstate` są rygorystycznie ignorowane w pliku `.gitignore`. Stan infrastruktury jest bezpiecznie przechowywany w zdalnym backendzie MinIO.
- **Hasła:** W repozytorium nie ma żadnych haseł w czystym tekście. Używamy wyłącznie wstrzykiwania sekretów z GitHuba jako zmiennych środowiskowych podczas pracy CI/CD.
