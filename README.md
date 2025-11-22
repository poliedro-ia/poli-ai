<div align="center">

# PoliAI - Geração de Imagens Educacionais com IA

**Flutter + Firebase • Web | Android | iOS**  
Criação e gerenciamento de imagens didáticas (Física/Química) com IA — rápido, simples e focado no professor.

<p>
  <a href="https://flutter.dev" title="Flutter"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/flutter/flutter-original.svg" alt="Flutter" height="34" style="margin:0 8px"/></a>
  <a href="https://dart.dev" title="Dart"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dart/dart-original.svg" alt="Dart" height="34" style="margin:0 8px"/></a>
  <a href="https://firebase.google.com" title="Firebase"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/firebase/firebase-plain.svg" alt="Firebase" height="34" style="margin:0 8px"/></a>
  <a href="https://www.typescriptlang.org/" title="TypeScript"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/typescript/typescript-original.svg" alt="TypeScript" height="34" style="margin:0 8px"/></a>
  <a href="https://nodejs.org" title="Node.js"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/nodejs/nodejs-original.svg" alt="Node.js" height="34" style="margin:0 8px"/></a>
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-0A84FF?logo=flutter&logoColor=white&labelColor=0B1220&style=for-the-badge"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&labelColor=0B1220&style=for-the-badge"></a>
  <a href="https://firebase.google.com"><img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20|%20Firestore%20|%20Storage%20|%20Functions-FFCA28?logo=firebase&logoColor=000&labelColor=0B1220&style=for-the-badge"></a>
</p>

<p align="center">
  <a href="#"><img alt="Platforms" src="https://img.shields.io/badge/Web%20|%20Android%20|%20iOS-1E293B?label=Platforms&logo=googlechrome&logoColor=white&style=for-the-badge"></a>
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/License-MIT-16A34A?logo=open-source-initiative&logoColor=white&style=for-the-badge"></a>
</p>

<p align="center">
  <a href="https://github.com/poliedro-ia/poli-ai/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/poliedro-ia/poli-ai?logo=github&color=FBBF24&labelColor=0B1220&style=for-the-badge"></a>
  <a href="https://github.com/poliedro-ia/poli-ai/forks"><img alt="Forks" src="https://img.shields.io/github/forks/poliedro-ia/poli-ai?logo=github&color=60A5FA&labelColor=0B1220&style=for-the-badge"></a>
  <a href="https://github.com/poliedro-ia/poli-ai/issues"><img alt="Issues" src="https://img.shields.io/github/issues/poliedro-ia/poli-ai?logo=github&color=EF4444&labelColor=0B1220&style=for-the-badge"></a>
</p>

</div>

---

## Sobre o PoliAI

PoliAI é um aplicativo **multiplataforma** para criação e gerenciamento de **imagens educacionais** (Física e Química) com **IA**, focado em rapidez, simplicidade e usabilidade para professores e alunos. O projeto foi construído com **Flutter** no front-end e **Firebase** no back-end (**Auth / Firestore / Storage / Cloud Functions**).

---

## Sumário

* [Destaques](#destaques)
* [Arquitetura](#arquitetura)
* [Stack Tecnológica](#stack-tecnológica)
* [Funcionalidades](#funcionalidades)
* [Estrutura do Projeto](#estrutura-do-projeto)
* [Modelo de Dados](#modelo-de-dados)
* [API de Geração (Cloud Function)](#api-de-geração-cloud-function)
* [Regras de Segurança](#regras-de-segurança)
* [Guia de Instalação](#guia-de-instalação)
* [Execução](#execução)
* [Build & Deploy](#build--deploy)
* [Testes (TDD/BDD)](#testes-tddbdd)
* [Administração](#administração)
* [Roadmap](#roadmap)
* [Troubleshooting](#troubleshooting)
* [Contribuição](#contribuição)
* [Licença](#licença)
* [Créditos](#créditos)

---

## Destaques

* 🎯 **Foco pedagógico**: prompt “didático” com rótulos claros, alto contraste e setas quando necessário.
* ⚡ **Geração rápida** via **Cloud Functions** callable (`generateImage`) com retorno imediato da imagem.
* ☁️ **Persistência** automática em **Firebase Storage** e metadados em **Firestore**.
* 🗂️ **Histórico** por usuário com grid responsivo, viewer com **zoom** e **download** (web/mobile) e **exclusão** com confirmação.
* 👤 **Conta & Perfil**: login/registro, verificação de e-mail, redefinição de senha, edição de displayName.
* 🔐 **Admin Page**: busca, filtros, paginação, **custom claim admin** e **bloqueio/desbloqueio** de usuários.
* 📱 **Responsivo**: UX adaptada para Web, Android e iOS. No **mobile**, “Minha Conta” fica no bottom-nav (evitando duplicidade na AppBar).

---

## Arquitetura

```
Flutter (Web/Android/iOS)
│
├── UI/UX (Material 3, LayoutBuilder, GridView/InteractiveViewer)
│
├── Firebase Auth ──► Cadastro/Login/Claims/Disabled
├── Cloud Firestore ─► users/{uid}/images (metadados)
├── Firebase Storage ─► images/{uid}/{yyyy}/{MM}/{dd}/{timestamp}.{ext}
└── Cloud Functions (southamerica-east1)
      └─ httpsCallable("generateImage") ─► Provedor IA ─► DataURL (png/webp)
```

---

## Stack Tecnológica

* **Frontend**: Flutter 3.x, Dart 3.x, Material 3, `InteractiveViewer`, `StreamBuilder`, `LayoutBuilder`.
* **Backend**: Firebase Cloud Functions (Node/TS ou JS), região **southamerica-east1**.
* **Serviços Firebase**: Authentication, Cloud Firestore, Cloud Storage.
* **Padrões**: DoD por feature, TDD/BDD onde aplicável, vertical slices.

---

## Funcionalidades

### Geração de Imagem

* Parâmetros: **Tema** (Física/Química), **Subárea**, **Estilo** (Vetorial/Realista/Desenho), **Aspect Ratio** (1:1, 3:2, 4:3, 16:9, 9:16), **Prompt** e **Didático** on/off.
* Chama a Function `generateImage`, recebe `imageDataUrl`, converte para bytes e salva no Storage. Metadados são gravados no Firestore.

### Resultado

* Preview imediato, **zoom** com `InteractiveViewer`, **download** e **copiar** (quando aplicável).

### Histórico

* Grid responsivo com colunas dinâmicas por breakpoint (≥640: 3, ≥900: 4, ≥1200: 5, ≥1400: 6).
* **Viewer** por item com zoom, **download** e **excluir** (remove Firestore + Storage).

### Conta

* Login/Registro, verificação e reset de senha, edição de nome.
* No **mobile**, navegação por **BottomNavigationBar** (Criar | Minha Conta | Admin*).

### Admin Page

* Listagem em **DataTable** (web) e **lista compacta** (mobile).
* **Filtros** por papel (Todos/Usuários/Admins) e status (Todos/Ativos/Bloqueados).
* **Ações**: Tornar/Remover admin (custom claims) e Bloquear/Desbloquear (disabled).
* **Paginação** por token; busca por nome/e-mail; snackbars de feedback.

---

## Estrutura do Projeto

```
poliai/
├─ lib/
│  ├─ common/
│  │  ├─ utils/
│  │  │  ├─ storage/
│  │  │  │  ├─ platform_downloader_stub.dart
│  │  │  │  ├─ platform_downloader_web.dart
│  │  │  │  └─ storage_utils.dart
│  │  │  ├─ media_utils_io.dart
│  │  │  ├─ media_utils_stub.dart
│  │  │  ├─ media_utils_web.dart
│  │  │  ├─ media_utils.dart
│  │  │  ├─ naming.dart
│  │  │  └─ validators.dart
│  │  ├─ widgets/
│  │  │  ├─ auth_button.dart
│  │  │  ├─ basic_app_bar.dart
│  │  │  ├─ skeleton.dart
│  │  │  ├─ smart_image.dart
│  │  │  └─ start_button.dart
│  │  ├─ core/
│  │  │  ├─ configs/
│  │  │  │  └─ assets/
│  │  │  │     └─ images.dart
│  │  │  ├─ theme/
│  │  │  │  ├─ colors.dart
│  │  │  │  ├─ theme_controller.dart
│  │  │  │  └─ theme.dart
│  │  │  ├─ motion/
│  │  │  │  ├─ motion.dart
│  │  │  │  └─ route.dart
│  │  │  └─ utils/   (ver acima)
│  │  └─ (bases compartilhadas entre módulos)
│  │
│  ├─ features/
│  │  ├─ account/
│  │  │  └─ edit_name_dialog.dart
│  │  ├─ admin/
│  │  │  ├─ admin_page.dart
│  │  │  └─ admin_service.dart
│  │  ├─ auth/
│  │  │  ├─ pages/
│  │  │  │  ├─ forgot_password_page.dart
│  │  │  │  ├─ login_page.dart
│  │  │  │  └─ register_page.dart
│  │  │  ├─ ui/
│  │  │  │  └─ auth_ui.dart
│  │  │  ├─ auth_service.dart
│  │  │  └─ firebase_error_mapper.dart
│  │  ├─ debug/
│  │  │  └─ appcheck_debug_page.dart
│  │  ├─ history/
│  │  │  ├─ ui/
│  │  │  │  └─ history_ui.dart
│  │  │  ├─ widgets/
│  │  │  │  ├─ history_card.dart
│  │  │  │  ├─ history_details.dart
│  │  │  │  ├─ viewer_dialog.dart
│  │  │  │  └─ history_page.dart
│  │  │  ├─ history_service.dart
│  │  │  └─ image_entry.dart
│  │  ├─ home/
│  │  │  ├─ models/
│  │  │  │  └─ image_item.dart
│  │  │  ├─ ui/
│  │  │  │  └─ home_ui.dart
│  │  │  ├─ web/
│  │  │  │  ├─ badge_item.dart
│  │  │  │  ├─ web_footer.dart
│  │  │  │  ├─ web_generator.dart
│  │  │  │  ├─ web_hero.dart
│  │  │  │  └─ web_navbar.dart
│  │  │  └─ widgets/
│  │  │     ├─ generator_panel.dart
│  │  │     ├─ image_grid.dart
│  │  │     ├─ image_zoom_dialog.dart
│  │  │     ├─ remote_history_grid.dart
│  │  │     ├─ result_panel.dart
│  │  │     ├─ home_page.dart
│  │  │     ├─ image_viewer_page.dart
│  │  │     └─ options.dart
│  │  ├─ users/
│  │  │  └─ users_service.dart
│  │  ├─ firebase_options.dart
│  │  └─ main.dart
│  │
│  └─ (código Flutter do app)
│
├─ functions/
│  ├─ src/
│  │  ├─ admin/
│  │  │  ├─ handlers.ts
│  │  │  └─ index.ts
│  │  ├─ config/
│  │  │  ├─ firebase.ts
│  │  │  └─ options.ts
│  │  ├─ http/
│  │  │  └─ guards.ts
│  │  ├─ image/
│  │  │  ├─ generate.ts
│  │  │  ├─ openrouter.ts
│  │  │  ├─ prompt.ts
│  │  │  ├─ schema.ts
│  │  │  └─ storage.ts
│  │  └─ index.ts
│  ├─ lib/                (build TS → JS)
│  ├─ scripts/            (utilitários de deploy/dev)
│  └─ node_modules/       (dependências)
│
└─ firebase.json
└─ .firebaserc
└─ pubspec.yaml
```

---

## Modelo de Dados

**Firestore**

* `users/{uid}/images/{docId}`

  * `downloadUrl: string`
  * `src: string` (fallback)
  * `storagePath: string`
  * `model: string`
  * `prompt: string`
  * `aspectRatio: string`
  * `temaSelecionado: string`
  * `subareaSelecionada: string`
  * `temaResolvido: string` (normalizado)
  * `subareaResolvida: string` (normalizado)
  * `createdAt: Timestamp(server)`

**Storage**

* `images/{uid}/{yyyy}/{MM}/{dd}/{timestamp}.{ext}`

---

## API de Geração (Cloud Function)

**Callable:** `generateImage` (região `southamerica-east1`)
**Entrada (JSON):**

```json
{
  "tema": "física|química",
  "subarea": "eletricidade|...|estequiometria",
  "estilo": "vetorial|realista|desenho",
  "aspectRatio": "1:1|3:2|4:3|16:9|9:16",
  "detalhes": "string com prompt final (didático opcional)"
}
```

**Saída (JSON):**

```json
{
  "imageDataUrl": "data:image/png;base64,...",
  "model": "provider/model-name",
  "promptUsado": "prompt final enviado ao provedor"
}
```

**Contratos importantes**

* `imageDataUrl` deve trazer **MIME** correto (`data:image/png|webp;...`) para que o app defina extensão.
* Erros devem ser lançados com **códigos claros** (`invalid-argument`, `internal`, etc.) para exibição amigável no cliente.

---

## Regras de Segurança


**Firestore (`firestore.rules`)**

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid}/images/{doc} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

**Storage (`storage.rules`)**

```rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /images/{uid}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

---

## Guia de Instalação

### Pré-requisitos

* Flutter 3.x / Dart 3.x (`flutter doctor` limpo)
* Conta Firebase (projeto ativo)
* Android SDK / Xcode (para mobile)
* Node 18+ para Functions

### Firebase

1. Crie um projeto no **Firebase Console**.
2. Ative **Authentication** (e-mail/senha).
3. Ative **Firestore** e **Storage**.
4. Configure **Cloud Functions** na região `southamerica-east1`.
5. Baixe e inclua as credenciais:

   * `google-services.json` (Android)
   * `GoogleService-Info.plist` (iOS)
   * `firebase_options.dart` (FlutterFire CLI) ou configuração manual.
6. Publique **Regras** do Firestore/Storage (seção acima).

### Functions

```bash
cd functions
npm i
npm run build
firebase deploy --only functions
```

---

## Execução

### Web

```bash
flutter config --enable-web
flutter run -d chrome
```

### Android

```bash
flutter run -d emulator-5554
```

### iOS

```bash
flutter run -d <device_id>
```

> Se necessário, execute `flutter pub get` e `flutter clean && flutter pub get` antes.

---

## Build & Deploy

### Web (Firebase Hosting ou outro)

```bash
flutter build web --release
# publicar o diretório build/web no serviço de sua escolha
```

### Android

```bash
flutter build apk --release
# ou appbundle: flutter build appbundle
```

### iOS

```bash
flutter build ios --release
# archive pelo Xcode para distribuição
```

---

## Testes (TDD/BDD)

* **TDD (unit/widget):**

  * Validador de prompt e estados de botão
  * Renderização de grid com quebras responsivas
  * Exibição de mensagens de erro (mocks)

* **BDD (caixa-preta):**

  * Cadastro/Login e fluxos de erro
  * Geração bem-sucedida (Storage + Firestore)
  * Histórico (viewer/zoom/download/exclusão)
  * Admin (promover/rebaixar admin, bloquear/desbloquear)

---

## Administração

### Tornar/Remover Admin (custom claims)

* A **Admin Page** consome um endpoint de administração (ou Admin SDK) para setar `customClaims.admin = true|false`.
* No cliente, `/home` habilita a aba “Admin” quando o token do usuário tiver `admin=true` (via `getIdTokenResult()`).

### Bloquear/Desbloquear Usuário

* Admin pode marcar `disabled=true|false` para impedir login subsequente.

> **Segurança:** operações administrativas devem ser protegidas por regras/roles e auditadas.

---

## Roadmap

* Presets de prompts por tema e subárea
* Filtros avançados no histórico (por data/tema/estilo)
* Exportação rápida para **slides** (PNG/PDF)
* Métricas/analytics por usuário e por tema
* Testes de widget de alto nível e CI (GitHub Actions)

---

## Troubleshooting

### `CERTIFICATE_VERIFY_FAILED` durante `flutter pub get` (Handshake/Hostname mismatch)

* Execute:

  * `flutter clean && flutter pub cache repair`
  * Verifique data/hora do SO (certificados dependem do relógio)
  * Teste outra rede/VPN
  * Em ambientes corporativos, configure o proxy do `pub`/`git`
* Atualize o Flutter:

  * `flutter upgrade`
* Como último recurso, limpe certificados customizados do SO que possam conflitar.

### Erros de permissão Firebase

* Confirme **regras** publicadas e **auth.uid** válido.
* Verifique se o caminho do Storage/Firestore bate com o código do app.

### Download não aparece no mobile

* No viewer e no card do histórico, o app expõe a ação **Baixar** no mobile usando utilitário de download nativo; garanta permissões de armazenamento quando necessário (Android 13−).

---

## Contribuição

1. Faça um fork do repositório
2. Crie uma branch: `feat/descrição-breve`
3. Commits pequenos e mensagens claras
4. Abra um PR descrevendo:

   * Contexto
   * Mudanças
   * Passos de teste

> Padrão de código: `dart format .` e `flutter analyze` devem passar limpos.

---

## Licença

Este projeto está licenciado sob a **MIT License**. Veja `LICENSE` para detalhes.

---

## Créditos

* Equipe PoliAI — **Product/Dev/QA**
* Professores e parceiros institucionais pelos feedbacks
* Comunidade Flutter/Firebase
