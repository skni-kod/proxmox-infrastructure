# 🚀 Proxmox Infrastructure

Repozytorium zawierające definicję IaC dla środowiska Proxmox. Całość jest zarządzana przy użyciu GitHub Actions, a wdrożenia odbywają się automatycznie poprzez Pull Requesty.

> **Uwaga:** To repozytorium zarządza IaC środowiska. Logika modułów i ról jest przechowywana w zewnętrznych, wersjonowanych repozytoriach:
>
> - `terraform-modules`: https://github.com/skni-kod/terraform-modules
> - `ansible-roles`: https://github.com/skni-kod/ansible-roles

## 🔄 Proces Wdrażania Zmian

Wdrażanie zmian opiera się na tworzeniu Pull Requesta:

1. **Utworzenie brancha:** Stwórz nową gałąź z najnowszego `main` i wprowadź zmiany (np. zmodyfikuj istniejący komponent lub stwórz nowy).
2. **Otwarcie Pull Requesta:** Wypchnij gałąź na GitHuba i otwórz PR.
3. **Automatyczna Walidacja (CI):** Workflow `pr-plan.yml` uruchomi się automatycznie:
   - Zwaliduje kod Terraforma.
   - Sprawdzi składnię Ansible (`ansible-lint`).
   - Wygeneruje i wyświetli `terraform plan`.
4. **Akceptacja Wdrożenia:** Jeśli akceptujesz wygenerowany plan, dodaj w Pull Requeście komentarz o treści:
   ```text
   /apply
   ```
   **Proces wdrożenia (CD):** Workflow pr-apply.yml przechwyci komendę, wdroży infrastrukturę (terraform apply), skonfiguruje maszyny (ansible-playbook) i automatycznie zamknie (zmerguje) Pull Request.

## 🛠️ Architektura i Stack Technologiczny

- **Provisioning (Sprzęt):** Terraform (provider `bpg/proxmox`)
- **Konfiguracja (System/Aplikacje):** Ansible (z wtyczką dynamic inventory `community.proxmox`)
- **Zarządzanie Stanem (Backend):** MinIO
- **CI/CD:** GitHub Actions

## 📂 Struktura Repozytorium

Repozytorium jest podzielone na komponenty infrastruktury (np. `k8s-cluster`). Każdy komponent zawiera własną warstwę provisioningową (Terraform) oraz konfiguracyjną (Ansible).

```text
proxmox-infrastructure/
├── .github/
│   └── workflows/
│       ├── pr-plan.yml      # Walidacja, Linting i Terraform Plan
│       └── pr-apply.yml     # Wdrażanie infrastruktury
├── components/
│   └── k8s-cluster/
│       ├── ansible/
│       │   ├── inventory.proxmox.yml  # Dynamic inventory Proxmox
│       │   ├── playbook.yml           # Główny playbook Ansible
│       │   └── requirements.yml       # Zewnętrzne, wersjonowane role
│       └── terraform/
│           ├── main.tf                # Główny plik tf, Odwołania do zewnętrznych modułów
│           ├── variables.tf           # Deklaracja zmiennych
│           └── *.tfvars               # Konfiguracja unikalna dla komponentu (IP, zasoby, nazwy)
└── README.md
```

## ⚡ CI/CD workflows (GitHub Actions)

Infrastruktura jest zarządzana przez dwa główne workflowy:

### 1. Walidacja i Planning (`pr-plan.yml`)

**Trigger:** Utworzenie lub aktualizacja (push) w Pull Requeście.
Workflow dba o jakość kodu i bezpieczeństwo wdrożenia, nie wprowadzając jeszcze żadnych zmian w środowisku.

- **Wykrywanie zmian:** Sprawdza, które komponenty infrastruktury (np. folder `components/k8s-cluster`) zostały zmodyfikowane.
- **Linting i Walidacja:** Sprawdza formatowanie Terraforma (`terraform fmt/validate`) oraz jakość kodu Ansible (`ansible-lint`).
- **Planowanie (Terraform Plan):** Generuje podgląd zmian (plan) w infrastrukturze i prezentuje go, dając możliwość weryfikacji przed faktycznym wdrożeniem.

### 2. Wdrożenie (`pr-apply.yml`)

**Trigger:** Dodanie komentarza o treści `/apply` w otwartym Pull Requeście.
Workflow ten odpowiada za faktyczną realizację zmian w środowisku Proxmox i jest uruchamiany po zatwierdzeniu planu.

- **Provisioning (Terraform):** Wykonuje `terraform apply -auto-approve`, tworząc lub modyfikując sprzęt wirtualny na Proxmoxie.
- **Konfiguracja (Ansible):** Pobiera dynamic inventory nowo utworzonych maszyn z Proxmoxa i uruchamia `ansible-playbook`, konfigurując systemy operacyjne i aplikacje.
- **Finalizacja:** Po pomyślnym nałożeniu zmian, workflow automatycznie merguje gałąź do `main` i usuwa branch tymczasowy, zamykając PR.

## 🔐 Wymagane Sekrety (GitHub Secrets)

Aby środowisko CI/CD mogło poprawnie funkcjonować, w ustawieniach repozytorium (_Settings -> Secrets and variables -> Actions_) muszą być zdefiniowane następujące sekrety:

### 1. Dostęp do węzłów i repozytoriów

- **`SSH_PRIVATE_KEY`** - Klucz prywatny ed25519 używany przez Ansible do logowania na wdrażane maszyny oraz do pobierania prywatnych ról z GitHuba.

### 2. Backend Terraforma (MinIO S3)

- **`MINIO_ACCESS_KEY`** - Identyfikator dostępu do MinIO.
- **`MINIO_SECRET_KEY`** - Klucz do MinIO.

### 3. Autoryzacja Proxmox (Terraform & Ansible)

- **`PROXMOX_API_TOKEN`** - Pełny token API w formacie wymaganym przez Terraforma (np. `user@pve!token=uuid`).
- **`PROXMOX_TOKEN_ID`** - Pierwsza część tokenu (np. `user@pve!token`) wymagana przez wtyczkę Ansible.
- **`PROXMOX_TOKEN_SECRET`** - Druga część tokenu, czyli sam klucz (UUID) wymagany przez wtyczkę Ansible.

## Opis części sprzętowej i konfiguracyjnej

<details>
<summary><b>🏗️ Część sprzętowa (Terraform)</b></summary>

Katalog `terraform/` wewnątrz każdego komponentu (np. `components/k8s-cluster/terraform/`) odpowiada za provisioning czystej infrastruktury wirtualnej w Proxmoxie (np. maszyny wirtualne czy kontenery).

Kluczowe elementy:

- **Zarządzanie Stanem w chmurze (MinIO / S3):**
  Plik `.tfstate` nigdy nie jest przetrzymywany w repozytorium (jest ignorowany przez Git). Zamiast tego, jest bezpiecznie przechowywany na serwerze MinIO. Zapewnia to bezpieczną pracę workflowów CI/CD i eliminuje ryzyko konfliktów przy jednoczesnych wdrożeniach.

- **Wykorzystanie modułów (`main.tf`):**
  Główny plik konfiguracyjny nie powiela niskopoziomowego kodu tworzenia maszyn. `main.tf` odwołuje się do zewnętrznych, wersjonowanych modułów (z repozytorium `terraform-modules`), przekazując do nich odpowiednie parametry. Dzięki temu logika tworzenia VM-ek, czy kontenerów jest ujednolicona.

- **Zmienne środowiskowe (`*.tfvars`):**
  Przechowuje jawne parametry wdrożenia, takie jak liczba węzłów (`count`), adresacja IP, wielkość dysków czy przydział pamięci.

- **Integracja z Ansible (Tagowanie maszyn):**
  Terraform nie tylko tworzy maszyny, ale również nadaje im odpowiednie metadane i tagi w Proxmoxie (np. `k8s-master`, `k8s-worker`). Na podstawie tych tagów wtyczka dynamic inventory Ansible wie, jakie role aplikacyjne przypisać do konkretnych maszyn tuż po ich uruchomieniu.

</details>

<details>
<summary><b>⚙️ Część konfiguracyjna (Ansible)</b></summary>

Katalog `ansible/` wewnątrz każdego komponentu (np. `components/k8s-cluster/ansible/`) odpowiada za post-provisioning. Podczas gdy Terraform dostarcza "czysty" sprzęt wirtualny, Ansible konfiguruje systemy operacyjne i instaluje aplikacje (m.in. przygotowanie środowiska).

Kluczowe elementy architektury konfiguracyjnej:

- **Dynamic Inventory (`inventory.proxmox.yml`):**
  Zamiast statycznej listy adresów IP, projekt korzysta z wtyczki `community.proxmox`. Ansible łączy się z API Proxmoxa i w locie pobiera listę uruchomionych maszyn wirtualnych. Grupowanie węzłów odbywa się na podstawie tagów lub nazw nadanych wcześniej przez Terraforma.

- **Zewnętrzne zależności (`requirements.yml`):**
  Repozytorium `proxmox-infrastructure` nie zawiera samej logiki konfiguracyjnej (tasków). Plik `requirements.yml` definiuje, z jakich zewnętrznych repozytoriów (`ansible-roles`) i w jakich **dokładnych wersjach** (tagach) pobrać konkretne role. Pozwala to na niezależny rozwój ról i bezpieczne, wersjonowane wdrożenia.

- **Wdrożenie ról (`playbook.yml`):**
  Główny punkt wejścia dla konfiguracji, który mapuje zaimportowane role do odpowiednich grup maszyn wykrytych w dynamic inventory

</details>

## 🛡️ Bezpieczeństwo i Dobre Praktyki

- **Pliki stanu:** Pliki `*.tfstate` są rygorystycznie ignorowane w pliku `.gitignore`. Stan infrastruktury jest bezpiecznie przechowywany w zdalnym backendzie MinIO.
- **Hasła:** W repozytorium nie ma żadnych haseł w czystym tekście. Używamy wyłącznie wstrzykiwania sekretów z GitHuba jako zmiennych środowiskowych podczas pracy CI/CD.
