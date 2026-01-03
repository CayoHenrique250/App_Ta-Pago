# 💪 Tá Pago! - Seu Treino Gamificado

> "Não é apenas sobre levantar peso, é sobre subir de nível."

O **Tá Pago!** é um aplicativo de rastreamento de treinos desenvolvido em Flutter que transforma sua rotina de academia em um RPG. Acompanhe seu progresso, tire fotos pós-treino e evolua seu rank de "Frango" até o "Olimpo".

## ✨ Funcionalidades

- **Gamificação de Níveis:**
  - O app calcula seu nível baseado no total de treinos concluídos.
  - Interface dinâmica que muda de cor (Cinza, Azul, Laranja, Vermelho, Dourado) conforme seu rank.
- **Registro de Treinos:**
  - Treinos divididos por grupos musculares (A, B, C, etc.).
  - Check-in diário com mensagem motivacional.
- **Histórico Visual:**
  - Calendário integrado para ver os dias treinados.
  - Upload de foto ("Shape do dia") para acompanhar a evolução física.
- **Perfil do Usuário:**
  - Gerenciamento de dados pessoais e foto de perfil.
  - Persistência de dados local (funciona offline).

## 🏆 Sistema de Ranks

| Nível | Rank | Treinos Necessários | Cor do Tema |
| :--- | :--- | :--- | :--- |
| 1 | **Frango** 🐣 | 0 - 4 | Blue Grey |
| 2 | **Em Construção** 🔨 | 5 - 14 | Teal Accent |
| 3 | **Ratão de Academia** 🐭 | 15 - 29 | Orange |
| 4 | **Monstro** 🔥 | 30 - 59 | Red Accent |
| 5 | **Olimpo** ⚡ | 60+ | Gold |

## 🛠 Tecnologias Utilizadas

- **Flutter & Dart**: Framework principal.
- **Provider**: Gerenciamento de estado.
- **SQFLite**: Banco de dados local para persistir histórico e usuário.
- **Image Picker & Path Provider**: Manipulação de fotos e arquivos locais.
- **Intl**: Formatação de datas.

## 🚀 Como rodar o projeto

1. Clone este repositório:
```bash
git clone [https://github.com/CayoHenrique250/App_TaPago.git](https://github.com/CayoHenrique250/App_TaPago.git)
```

2. Instale as dependências:

```bash
flutter pub get
```

3. Execute o app:

```bash
flutter run
```

