# Tripee – Histórico de Corridas

## Como rodar

**Pré-requisitos:** Flutter 3.24.0

```bash
git clone https://github.com/rickfpdev/tripee-app
cd tripee_app
flutter pub get
flutter run
```

Para rodar os testes:

```bash
flutter test
```

---

## API

URL base: `https://tripee-interview.azurewebsites.net/v1`

---

## Melhorias além do design

- Testes automatizados cobrindo models, providers e repository
- Adicionado sessão de informações da rota na tela de detalhes da corrida, que mostra distância e duração da rota realizada em comparação a rota estimada

## Lacunas conhecidas

- O mapa não exibe tiles de rua reais por ausência de API key do Google Maps. As polylines são decodificadas e desenhadas corretamente, mas sobre um fundo estático.
- O endpoint de detalhe da API de teste retorna sempre o mesmo dado independente do id — comportamento da API, não da implementação.
