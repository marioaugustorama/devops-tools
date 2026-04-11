# Cliente __CLIENT_NAME__

Estrutura base do contexto:

- `.kube/config`: kubeconfig dedicado
- `.ssh/`: chaves, config e known_hosts
- `.docker/`: config do Docker/registry
- `wireguard/`: perfis WireGuard
- `openvpn/`: perfis OpenVPN
- `env.sh`: exports carregados no `client use`
- `aliases.sh`: aliases/funções do cliente
- `bin/`: scripts auxiliares do cliente
