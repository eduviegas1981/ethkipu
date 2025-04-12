    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.26;

    /// @title KipuBank - Um banco simples para armazenar ETH com limites e controle de usuários
    contract KipuBank {
        address public immutable i_owner; // Proprietário do contrato
        uint256 public immutable i_bankCap; // Limite máximo de ETH no contrato
        uint256 public immutable i_limitPerWithdrawal; // Limite máximo por saque

        // Constante de exemplo (pode ser usada futuramente)
        uint256 public constant MIN_DEPOSIT = 0.01 ether;

        // Armazenamento de saldos e usuários autorizados
        mapping(address => uint256) private s_balances;
        mapping(address => bool) private s_usuariosAutorizados;
        address[] private s_listaUsuarios;

        // Eventos
        event KipuBank_Deposito(address indexed usuario, uint256 valor);
        event KipuBank_Saque(address indexed usuario, uint256 valor);
        event KipuBank_UsuarioRegistrado(address indexed usuario);
        event KipuBank_UsuarioDesabilitado(address indexed usuario);
        event KipuBank_UsuarioHabilitado(address indexed usuario);

        // Erros customizados
        error KipuBank_LimiteExcedido();
        error KipuBank_SaldoInsuficiente();
        error KipuBank_FalhaTransferencia();
        error KipuBank_NaoAutorizado();

        // Construtor
        constructor(uint256 _bankCap, uint256 _limitPerWithdrawal) {
            i_owner = msg.sender;
            i_bankCap = _bankCap;
            i_limitPerWithdrawal = _limitPerWithdrawal;
        }

        // Modificador: verifica se o remetente tem saldo suficiente
        modifier saldoSuficiente(uint256 valor) {
            if (s_balances[msg.sender] < valor) {
                revert KipuBank_SaldoInsuficiente();
            }
            _;
        }

        // Modificador: apenas usuários autorizados
        modifier apenasAutorizado() {
            if (!s_usuariosAutorizados[msg.sender]) {
                revert KipuBank_NaoAutorizado();
            }
            _;
        }

        // Depósito de ETH
        function deposito() external payable apenasAutorizado {
            require(msg.value > 0, "Valor do deposito deve ser maior que zero.");
            if (address(this).balance > i_bankCap) {
                revert KipuBank_LimiteExcedido();
            }

            s_balances[msg.sender] += msg.value;
            emit KipuBank_Deposito(msg.sender, msg.value);
        }

        // Saque de ETH
        function saque(uint256 valor) external apenasAutorizado saldoSuficiente(valor) {
            require(valor > 0, "Valor do saque deve ser maior que zero.");
            require(valor <= i_limitPerWithdrawal, "Valor excede o limite por saque.");

            _transferirETH(msg.sender, valor);
            emit KipuBank_Saque(msg.sender, valor);
        }

        // Registrar novo usuário
        function registrarUsuario(address usuario) external {
            require(msg.sender == i_owner, "Apenas o dono pode registrar usuarios.");
            if (!s_usuariosAutorizados[usuario]) {
                s_usuariosAutorizados[usuario] = true;
                s_listaUsuarios.push(usuario);
                emit KipuBank_UsuarioRegistrado(usuario);
            }
        }

        // Desabilitar usuário
        function desabilitarUsuario(address usuario) external {
            require(msg.sender == i_owner, "Apenas o dono pode desabilitar usuarios.");
            require(s_usuariosAutorizados[usuario], "Usuario ja esta desabilitado.");
            s_usuariosAutorizados[usuario] = false;
            emit KipuBank_UsuarioDesabilitado(usuario);
        }

        // Reabilitar usuário
        function habilitarUsuario(address usuario) external {
            require(msg.sender == i_owner, "Apenas o dono pode habilitar usuarios.");
            require(!s_usuariosAutorizados[usuario], "Usuario ja esta habilitado.");
            s_usuariosAutorizados[usuario] = true;
            emit KipuBank_UsuarioHabilitado(usuario);
        }

        // Ver lista de usuários
        function listarUsuariosAutorizados() external view returns (address[] memory) {
            return s_listaUsuarios;
        }

        // Consulta de saldo do próprio usuário
        function consultarMeuSaldo() external view returns (uint256) {
            return s_balances[msg.sender];
        }

        // Consulta do saldo total do contrato (visível apenas ao owner)
        function saldoTotalContrato() external view returns (uint256) {
            require(msg.sender == i_owner, "Apenas o dono pode consultar o saldo total.");
            return address(this).balance;
        }

        // Função interna de transferência
        function _transferirETH(address destinatario, uint256 valor) internal {
            s_balances[destinatario] -= valor;

            (bool sucesso, ) = payable(destinatario).call{value: valor}("");
            if (!sucesso) {
                revert KipuBank_FalhaTransferencia();
            }
        }
    }
