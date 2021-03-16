#!/usr/bin/env tclsh

#---------------------------------------------------------
# Author: NidoBr
# E-mail: < coqecoisa@gmail.com >
# Github: < https://github.com/NIDObr >
# Versão: Alpha 15/03/2021
# Licença: BSD 3-Clause "New" or "Revised" License
# OPLTOOL:
#	Small web server
#---------------------------------------------------------

#-------------------------------------------------Package

# Log tool
#package require logtool 1.0

#----------------------------------------------------Vars

# Nome do programa
set ::_pname $argv0
# Diretorio raiz (onde estara o site)
set ::_root "/home/nido/Documentos/scripts/html/repo_opl"
#1 Primeira pagina
set ::_index "/index.html"
# Porta do servidor
set _port "6921"

#--------------------------------------------------Funções

# Inicia o servidor
proc InitServer { port } {
	# Cria o canal de rede na porta especificada e chama a função InirCfg
	set ::_wssock [ socket -server InitCfg $port ]
	puts "[ clock format [ clock seconds ] -format {%b %d %H:%M:%S} ] - Servidor iniciado.\n"
	# Mantem o programa rodando em loop
	vwait forever
}
# Indentifica se o canal esta disponivel
proc InitCfg { _sockid _ipremot port } {
	# Se o canal estiver disponivel chama a função cfgWebSW
	fileevent $_sockid readable [ list cfgWebSW $_sockid $_ipremot ]
}
# Configura o canal
proc cfgWebSW { _sockid _ipremot } {
	fconfigure $_sockid -translation binary -buffering full
	fconfigure $_sockid -blocking 0
	if { [ fblocked $_sockid ] } then { return }
	fileevent $_sockid readable [ list WebSW $_sockid ]
}
# Trasfere as paginas ao browser
proc WebSW { _sockid } {
	set _sockline [ gets $_sockid ]
	set _sockline [ regsub "GET " $_sockline "" ]
 	set _sockline [ regsub " HTTP/1.1" $_sockline "" ]
	# Se não for solicitada uma pagina especifica, exibe a pagina padrão 
	if { [ eval file exist "$::_root$_sockline" ] == 0 } {
		puts $_sockid "HTTP/1.0 404 Not found"
		puts $_sockid ""
		puts $_sockid "<html><head><title>404 Not found</title></head>"
		puts $_sockid "<body><center>"
		puts $_sockid "<h1>Not Found.</h1><h2>The url was not found on the server, returning error 404</h2>"
		puts $_sockid "</center></body></html>"
		close $_sockid
	} else {
		if { [ eval string index $_sockline 1 ] == "" } {
			set _pfile [ open "$::_root$::_index" r ]
		} else {
			set _pfile [ eval open $::_root$_sockline r ]
		}
		puts $_sockid "HTTP/1.1 200 OK"
		puts $_sockid ""
		set _header [ read $_sockid ]
		puts "$_header"
		fconfigure $_pfile -translation binary
		# Transfere os dados ao browser
		fileevent $_sockid readable [ fcopy $_pfile $_sockid -command [ list done $_pfile $_sockid ] ]
	}
}
# Fecha os canais referente ao socket e ao arquivo enviado ao browser
proc done { _pfile _sockid _transferbit } {
	close $_pfile
	close $_sockid
}

#-------------------------------------------------Principal

# Start log
#logtool:log_mes "Iniciando serviço..." $::_pname "INFO"

puts "[ clock format [ clock seconds ] -format {%b %d %H:%M:%S} ] - Iniciando."
# Inicia o servidor na porta especificada
InitServer $_port
