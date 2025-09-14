# ExportDataBase Runbook

Este repositório contém o **Runbook PowerShell** `RunbookExportDataSQL.ps1` cujo objetivo é automatizar a exportação de uma base de dados SQL PaaS no Azure para um Storage Account, gerando um arquivo `.bacpac` de backup, para posterior restauração em ambiente de desenvolvimento.

---

## Sumário

- [Visão Geral](#visão-geral)  
- [Requisitos](#requisitos)  
- [Como Funciona](#como-funciona)  
- [Configuração](#configuração)  
- [Permissões Necessárias](#permissões-necessárias)  
- [Como Usar](#como-usar)  
- [Segurança](#segurança)  
- [Benefícios](#benefícios)  
- [Avisos e Considerações](#avisos-e-considerações)  

---

## Visão Geral

Este runbook é executado por meio de uma **Automation Account** no Azure e realiza os seguintes passos:

1. Autentica-se usando identidade gerenciada ou credenciais armazenadas com segurança.  
2. Exporta a base de dados SQL (PaaS) para um arquivo `.bacpac` numa conta de Storage.  
3. Armazena o arquivo no container apropriado.  
4. Permite restaurar esse `.bacpac` em ambiente de desenvolvimento (isolado).  

---

## Requisitos

- SQL Database PaaS no Azure.  
- Storage Account com Blob Container configurado para armazenamento dos `.bacpac`.  
- Azure Automation Account com Runbook PowerShell.  
- Azure Key Vault para armazenar credenciais (usuário e senha do banco).  
- Identidade gerenciada (Managed Identity) ou conta de serviço para automação.  

---

## Como Funciona

- O `RunbookExportDataSQL.ps1` contém lógica para exportar o banco de dados SQL usando comandos Azure (por exemplo, `New-AzSqlDatabaseExport` ou similar).  
- O script recupera credenciais seguras do Key Vault.  
- Gera nome do arquivo `.bacpac`, geralmente incluindo data/hora para versionamento.  
- Envia/exporta para Storage Account.  
- Possivelmente valida/faz polling do status da exportação até conclusão.  

---

## Configuração

| Item | Detalhes |
|---|---|
| Parâmetros obrigatórios do Runbook | Nome do banco, servidor, resource group, conta de storage, container, etc. |
| Armazenamento de credenciais | Key Vault – segredos para `AdministratorLogin` e `AdministratorLoginPassword` |
| Identidade de execução | Managed Identity associada à Automation Account ou credenciais de serviço |
| Variáveis do ambiente | Podem ser configuradas como variáveis/fonte de configuração na Automation Account ou Assets (variáveis, credenciais) |

---

## Permissões Necessárias

A identidade que executa o runbook deve possuir, pelo menos, os seguintes papéis/permssões:

- **Contributor** no banco SQL (permitindo iniciar/exportar a base).  
- **Contributor** ou **Storage Blob Data Contributor** no container do Storage Account (para gravar o `.bacpac`).  
- **Leitor** ou **User/Reader** no Key Vault para buscar segredos (usuário e senha).  

---

## Como Usar

1. Importar o script `RunbookExportDataSQL.ps1` para a sua Automation Account.  
2. Configurar as credenciais/secrets no Key Vault.  
3. Associar a Managed Identity ou outra conta de automação com as permissões necessárias.  
4. Inserir/definir parâmetros do runbook (resource group, servidor, banco, storage, container, etc.).  
5. Testar execução manualmente.  
6. Programar agendamento (schedule) se desejar automação periódica.  

---

## Segurança

- Uso de **Key Vault** para segredos sensíveis (senha, usuário) — evita exposição no código.  
- Uso de **Managed Identity** quando possível, reduzindo credenciais fixas.  
- Controle de acesso via **RBAC** estrito, somente às identidades necessárias.  
- Isolamento do ambiente de desenvolvimento para restauro, evitando impacto em produção.  

---

## Benefícios

- Backup seguro e versionado das bases de dados.  
- Capacidade de restauração em servidor de desenvolvimento sem sobrecarregar produção.  
- Automação do processo: redução de erros humanos e de tarefas manuais repetitivas.  
- Governança melhorada: rastreabilidade, auditoria, uso de boas práticas de segurança.  

---

## Avisos e Considerações

- O Storage Account **precisa estar acessível publicamente** para que o Azure SQL export (ou serviço equivalente usado) possa gravar o `.bacpac` (dependendo do serviço). Se tudo estiver com Private Endpoint ou firewalls muito restritos, a exportação pode falhar.  
- Limitações de tamanho de exportação: arquivos `.bacpac` muito grandes podem demorar ou falhar; verificar limites do serviço Azure SQL Export/Import.  
- Tempo de execução pode variar bastante conforme volume de dados.  
- Manter monitoração ou alertas para falhas de exportação.  

---

## Contribuição

Se quiser contribuir, pode:

- Reportar issues caso encontre bugs ou limitações.  
- Sugerir melhorias no script (ex: limpeza automática de backups antigos, paralelismo).  
- Adicionar testes ou exemplos de configuração para diferentes cenários.  

---

## Licença

Este projeto está disponibilizado sob a [LICENÇA que você definir — ex: MIT, Apache, etc.].  

---

## Contatos

Em caso de dúvidas ou sugestões:

- Autor: (seu nome ou contato)  
- Projeto GitHub: `ErickMedeiros/exportDataBase`  

---

