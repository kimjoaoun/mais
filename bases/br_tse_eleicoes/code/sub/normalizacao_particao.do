
//----------------------------------------------------------------------------//
// build: limpeza e normalizacao
//----------------------------------------------------------------------------//

//-------------------------------------------------//
// candidatos
//-------------------------------------------------//

use "output/candidatos_1994.dta", clear
foreach ano of numlist 1996(2)2020 {
	append using "output/candidatos_`ano'.dta"
}
*

drop if turno == 2
drop if ano == .
drop turno resultado

merge m:1 cpf titulo_eleitoral nome using "output/id_candidato_bd.dta"
drop if _merge == 2 & ano >= 1998
drop _merge

gen aux_id = _n	// id auxiliar para merge

tempfile candidatos
save `candidatos'

//------------//
// limpando
// duplicadas
//------------//

keep if id_candidato_bd != .

local vars ano tipo_eleicao sigla_uf id_municipio_tse numero cargo id_candidato_bd
duplicates tag `vars', gen(dup)
duplicates drop `vars' if dup > 0, force
drop dup

local vars ano tipo_eleicao sigla_uf id_municipio_tse numero cargo
duplicates tag `vars', gen(dup)
drop if dup > 0 & situacao != "deferido"
drop dup

local vars ano tipo_eleicao sigla_uf id_municipio_tse numero cargo
duplicates tag `vars', gen(dup)
drop if dup > 0
drop dup

local vars id_candidato_bd ano tipo_eleicao
duplicates drop `vars', force

save "output/norm_candidatos.dta", replace

//------------//
// particiona
//------------//

use `candidatos'

merge 1:1 aux_id using "output/norm_candidatos.dta"
drop _merge aux_id

drop coligacao composicao

order ano tipo_eleicao sigla_uf id_municipio id_municipio_tse ///
	id_candidato_bd cpf titulo_eleitoral sequencial numero nome nome_urna numero_partido sigla_partido cargo

compress

tempfile candidatos
save `candidatos'

!mkdir "output/candidatos"

levelsof ano, l(anos)
foreach ano in `anos' {
	
	use `candidatos' if ano == `ano', clear
	
	!mkdir "output/candidatos/ano=`ano'"
	
	levelsof sigla_uf, l(estados_`ano')
	foreach sigla_uf in `estados_`ano'' {
		
		!mkdir "output/candidatos/ano=`ano'/sigla_uf=`sigla_uf'"
		
		preserve
			keep if ano == `ano' & sigla_uf == "`sigla_uf'"
			drop ano sigla_uf
			export delimited "output/candidatos/ano=`ano'/sigla_uf=`sigla_uf'/candidatos.csv", replace
		restore
	}
}
*

//-------------------------------------------------//
// norm_partidos
//-------------------------------------------------//

use "output/partidos_1990.dta", clear
foreach ano of numlist 1994(2)2020 {
	append using "output/partidos_`ano'.dta"
}
*

keep ano numero sigla

duplicates drop

compress

save "output/norm_partidos.dta", replace

//-------------------------------------------------//
// partidos
//-------------------------------------------------//

!mkdir "output/partidos"

foreach ano of numlist 1990 1994(2)2020 {
	
	!mkdir "output/partidos/ano=`ano'"
	
	use "output/partidos_`ano'.dta", clear
	
	levelsof sigla_uf, l(estados)
	
	foreach sigla_uf in `estados' {
		
		!mkdir "output/partidos/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use "output/partidos_`ano'.dta", clear
		keep if ano == `ano' & sigla_uf == "`sigla_uf'"
		drop ano sigla_uf
		export delimited "output/partidos/ano=`ano'/sigla_uf=`sigla_uf'/partidos.csv", replace
		
	}
}
*

//-------------------------------------------------//
// resultados municipio-zona
//-------------------------------------------------//


use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 0
keep id_candidato_bd ano tipo_eleicao sigla_uf id_municipio_tse cargo numero

tempfile candidatos_mod0
save `candidatos_mod0'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo != "presidente"
keep id_candidato_bd ano tipo_eleicao sigla_uf cargo numero

tempfile candidatos_mod2_estadual
save `candidatos_mod2_estadual'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo == "presidente"
keep id_candidato_bd ano tipo_eleicao cargo numero

tempfile candidatos_mod2_presid
save `candidatos_mod2_presid'

!mkdir "output/resultados_candidato_municipio_zona"
!mkdir "output/resultados_partido_municipio_zona"

foreach ano of numlist 1994(2)2020 {
	
	//---------------------//
	// candidato-municipio-zona
	//---------------------//
	
	use "output/resultados_candidato_municipio_zona_`ano'.dta", clear
	
	ren numero_candidato numero
	
	if mod(`ano', 4) == 0 {
		
		merge m:1 ano tipo_eleicao sigla_uf id_municipio_tse cargo numero using `candidatos_mod0'
		drop if _merge == 2
		drop _merge
		
	}
	else {
		
		preserve
			
			keep if cargo != "presidente"
			
			merge m:1 ano tipo_eleicao sigla_uf cargo numero using `candidatos_mod2_estadual'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_estadual
			save `resultados_mod2_estadual'
			
		restore
		preserve
			
			keep if cargo == "presidente"
			
			merge m:1 ano tipo_eleicao cargo numero using `candidatos_mod2_presid'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_presid
			save `resultados_mod2_presid'
			
		restore
		
		use `resultados_mod2_estadual', clear
		append using `resultados_mod2_presid'
		
	}
	*
	
	ren numero numero_candidato
	
	drop nome_candidato nome_urna_candidato sequencial_candidato coligacao composicao
	
	local vars ano turno tipo_eleicao sigla_uf id_municipio id_municipio_tse zona cargo sigla_partido numero_candidato id_candidato_bd votos resultado
	
	order `vars'
	sort  `vars'
	
	tempfile resultados_candidato_munzona
	save `resultados_candidato_munzona'
	
	//------------//
	// particiona
	//------------//
	
	!mkdir "output/resultados_candidato_municipio_zona/ano=`ano'"
	
	use `resultados_candidato_munzona', clear
	
	levelsof sigla_uf, l(estados)
	foreach sigla_uf in `estados' {
		
		!mkdir "output/resultados_candidato_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use `resultados_candidato_munzona', clear
		keep if ano == `ano' & sigla_uf == "`sigla_uf'"
		drop ano sigla_uf
		export delimited "output/resultados_candidato_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'/resultados_candidato_municipio_zona.csv", replace
		
	}
	*
	
	//---------------------//
	// partido-municipio-zona
	//---------------------//
	
	use "output/resultados_partido_municipio_zona_`ano'.dta", clear
	
	drop coligacao composicao
	
	local vars ano turno tipo_eleicao sigla_uf id_municipio id_municipio_tse zona cargo sigla_partido
	
	order `vars'
	sort  `vars'
	
	tempfile resultados_partido_munzona
	save `resultados_partido_munzona'
	
	//------------//
	// particiona
	//------------//
	
	!mkdir "output/resultados_partido_municipio_zona/ano=`ano'"
	
	use `resultados_partido_munzona', clear
	
	levelsof sigla_uf, l(estados)
	foreach sigla_uf in `estados' {
		
		!mkdir "output/resultados_partido_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use `resultados_partido_munzona', clear
		keep if ano == `ano' & sigla_uf == "`sigla_uf'"
		drop ano sigla_uf
		export delimited "output/resultados_partido_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'/resultados_partido_municipio_zona.csv", replace
		
	}
	*
	
}
*

//-------------------------------------------------//
// resultados secao
//-------------------------------------------------//

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 0
keep id_candidato_bd ano tipo_eleicao sigla_uf id_municipio_tse cargo numero sigla_partido

tempfile candidatos_mod0
save `candidatos_mod0'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo != "presidente"
keep id_candidato_bd ano tipo_eleicao sigla_uf cargo numero sigla_partido

tempfile candidatos_mod2_estadual
save `candidatos_mod2_estadual'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo == "presidente"
keep id_candidato_bd ano tipo_eleicao cargo numero sigla_partido

tempfile candidatos_mod2_presid
save `candidatos_mod2_presid'

!mkdir "output/resultados_candidato_secao"
!mkdir "output/resultados_partido_secao"

foreach ano of numlist 1994(2)2020 {
	
	//---------------------//
	// candidato
	//---------------------//
	
	use "output/resultados_candidato_secao_`ano'.dta", clear
	
	ren numero_candidato numero
	
	if mod(`ano', 4) == 0 {
		
		merge m:1 ano tipo_eleicao sigla_uf id_municipio_tse cargo numero using `candidatos_mod0'
		drop if _merge == 2
		drop _merge
		
	}
	else {
		
		preserve
			
			keep if cargo != "presidente"
			
			merge m:1 ano tipo_eleicao sigla_uf cargo numero using `candidatos_mod2_estadual'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_estadual
			save `resultados_mod2_estadual'
			
		restore
		preserve
			
			keep if cargo == "presidente"
			
			merge m:1 ano tipo_eleicao cargo numero using `candidatos_mod2_presid'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_presid
			save `resultados_mod2_presid'
			
		restore
		
		use `resultados_mod2_estadual', clear
		append using `resultados_mod2_presid'
		
	}
	*
	
	ren numero numero_candidato
	
	local vars ano turno tipo_eleicao sigla_uf id_municipio id_municipio_tse zona secao cargo sigla_partido numero_candidato id_candidato_bd votos
	
	order `vars'
	sort  `vars'
	
	tempfile resultados_candidato_secao
	save `resultados_candidato_secao'
	
	//------------//
	// particiona
	//------------//
	
	!mkdir "output/resultados_candidato_secao/ano=`ano'"
	
	use `resultados_candidato_secao', clear
	
	levelsof sigla_uf, l(estados)
	foreach sigla_uf in `estados' {
		
		!mkdir "output/resultados_candidato_secao/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use `resultados_candidato_secao' if ano == `ano' & sigla_uf == "`sigla_uf'", clear
		drop ano sigla_uf
		export delimited "output/resultados_candidato_secao/ano=`ano'/sigla_uf=`sigla_uf'/resultados_candidato_secao.csv", replace
		
	}
	*
	
	//---------------------//
	// partido
	//---------------------//
	
	use "output/resultados_partido_secao_`ano'.dta", clear
	
	ren numero_partido numero
	
	merge m:1 ano numero using "output/norm_partidos.dta"
	drop if _merge == 2
	drop _merge
	
	drop numero
	ren sigla sigla_partido
	
	local vars ano turno tipo_eleicao sigla_uf id_municipio_tse zona secao cargo sigla_partido
	
	order `vars'
	sort  `vars'
	
	tempfile resultados_partido_secao
	save `resultados_partido_secao'
	
	//------------//
	// particiona
	//------------//
	
	!mkdir "output/resultados_partido_secao/ano=`ano'"
	
	use `resultados_partido_secao', clear
	
	levelsof sigla_uf, l(estados)
	foreach sigla_uf in `estados' {
		
		!mkdir "output/resultados_partido_secao/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use `resultados_partido_secao' if ano == `ano' & sigla_uf == "`sigla_uf'", clear
		drop ano sigla_uf
		export delimited "output/resultados_partido_secao/ano=`ano'/sigla_uf=`sigla_uf'/resultados_partido_secao.csv", replace
		
	}
}
*

//-------------------------------------------------//
// perfil eleitorado
//-------------------------------------------------//

!mkdir "output/perfil_eleitorado_municipio_zona"

foreach ano of numlist 1994(2)2020 {
	
	!mkdir "output/perfil_eleitorado_municipio_zona/ano=`ano'"
	
	use "output/perfil_eleitorado_municipio_zona_`ano'.dta", clear
	levelsof sigla_uf, l(estados)
	
	foreach sigla_uf in `estados' {
		
		!mkdir "output/perfil_eleitorado_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use "output/perfil_eleitorado_municipio_zona_`ano'.dta", clear
		keep if sigla_uf == "`sigla_uf'"
		drop ano sigla_uf
		export delimited "output/perfil_eleitorado_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'/perfil_eleitorado_municipio_zona.csv", replace
		
	}
}
*

//-------------------------------------------------//
// perfil eleitorado - local votacao
//-------------------------------------------------//

!mkdir "output/perfil_eleitorado_local_votacao"

foreach ano of numlist 2016(2)2020 {
	
	!mkdir "output/perfil_eleitorado_local_votacao/ano=`ano'"
	
	use "output/perfil_eleitorado_local_votacao.dta", clear
	keep if ano == `ano'
	levelsof sigla_uf, l(estados)
	
	foreach sigla_uf in `estados' {
		
		!mkdir "output/perfil_eleitorado_local_votacao/ano=`ano'/sigla_uf=`sigla_uf'"
		
		preserve
			keep if sigla_uf == "`sigla_uf'"
			drop ano sigla_uf
			export delimited "output/perfil_eleitorado_local_votacao/ano=`ano'/sigla_uf=`sigla_uf'/perfil_eleitorado_local_votacao.csv", replace
		restore
		
	}
}
*

//-------------------------------------------------//
// perfil eleitorado - secao eleitoral
//-------------------------------------------------//

!mkdir "output/perfil_eleitorado_secao"

foreach ano of numlist 2008(2)2020 {
	
	!mkdir "output/perfil_eleitorado_secao/ano=`ano'"
	
	use "output/perfil_eleitorado_secao_`ano'.dta", clear
	levelsof sigla_uf, l(estados)
	
	foreach sigla_uf in `estados' {
		
		!mkdir "output/perfil_eleitorado_secao/ano=`ano'/sigla_uf=`sigla_uf'"
		
		preserve
			keep if sigla_uf == "`sigla_uf'"
			drop ano sigla_uf
			export delimited "output/perfil_eleitorado_secao/ano=`ano'/sigla_uf=`sigla_uf'/perfil_eleitorado_secao.csv", replace
		restore
		
	}
}
*

//-------------------------------------------------//
// detalhes votacao municipio-zona
//-------------------------------------------------//

!mkdir "output/detalhes_votacao_municipio_zona"

foreach ano of numlist 1994(2)2020 {
	
	!mkdir "output/detalhes_votacao_municipio_zona/ano=`ano'"
	
	use "output/detalhes_votacao_municipio_zona_`ano'.dta", clear
	
	levelsof sigla_uf, l(estados)
	
	foreach sigla_uf in `estados' {
		
		!mkdir "output/detalhes_votacao_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use "output/detalhes_votacao_municipio_zona_`ano'.dta", clear
		keep if sigla_uf == "`sigla_uf'"
		drop ano sigla_uf
		export delimited "output/detalhes_votacao_municipio_zona/ano=`ano'/sigla_uf=`sigla_uf'/detalhes_votacao_municipio_zona.csv", replace
		
	}
}
*

//-------------------------------------------------//
// detalhes votacao secao
//-------------------------------------------------//

!mkdir "output/detalhes_votacao_secao"

foreach ano of numlist 1994(2)2020 {
	
	!mkdir "output/detalhes_votacao_secao/ano=`ano'"
	
	use "output/detalhes_votacao_secao_`ano'.dta", clear
	
	levelsof sigla_uf, l(estados)
	
	foreach sigla_uf in `estados' {
		
		!mkdir "output/detalhes_votacao_secao/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use "output/detalhes_votacao_secao_`ano'.dta", clear
		keep if sigla_uf == "`sigla_uf'"
		drop ano sigla_uf
		export delimited "output/detalhes_votacao_secao/ano=`ano'/sigla_uf=`sigla_uf'/detalhes_votacao_secao.csv", replace
		
	}
}
*

//-------------------------------------------------//
// vagas
//-------------------------------------------------//

use "output/vagas_1994.dta", clear
foreach ano of numlist 1996(2)2020 {
	append using "output/vagas_`ano'.dta"
}
save "output/norm_vagas.dta", replace

!mkdir "output/vagas"

use "output/norm_vagas.dta", clear

levelsof ano, l(anos)
foreach ano in `anos' {
	levelsof sigla_uf if ano == `ano', l(estados_`ano')
}
*

foreach ano in `anos' {
	
	!mkdir "output/vagas/ano=`ano'"
	
	foreach sigla_uf in `estados_`ano'' {
		
		!mkdir "output/vagas/ano=`ano'/sigla_uf=`sigla_uf'"
		
		use "output/norm_vagas.dta", clear
		keep if ano == `ano' & sigla_uf == "`sigla_uf'"
		drop ano sigla_uf
		export delimited "output/vagas/ano=`ano'/sigla_uf=`sigla_uf'/vagas.csv", replace
		
	}
}
*

//-------------------------------------------------//
// filiacao partidaria
//-------------------------------------------------//

!mkdir "output/filiacao_partidaria"

use "output/filiacao_partidaria.dta", clear

levelsof sigla_uf, l(estados)
foreach estado in `estados' {
	levelsof sigla_partido if sigla_uf == "`estado'", l(partidos_`estado')
}
*

foreach estado in `estados' {
	
	!mkdir "output/filiacao_partidaria/sigla_uf=`estado'"
	
	foreach partido in `partidos_`estado'' {
		
		!mkdir "output/filiacao_partidaria/sigla_uf=`estado'/sigla_partido=`partido'"
		
		use "output/filiacao_partidaria.dta", clear
		keep if sigla_uf == "`estado'" & sigla_partido == "`partido'"
		drop sigla_uf sigla_partido
		export delimited "output/filiacao_partidaria/sigla_uf=`estado'/sigla_partido=`partido'/filiacao_partidaria.csv", replace
		
	}
}
*


//-------------------------------------------------//
// bens - candidato
//-------------------------------------------------//

//--------------------//
// merge com id_candidato
// particiona
//--------------------//

use "output/norm_candidatos.dta", clear

keep if ano >= 2006

keep id_candidato_bd ano tipo_eleicao sigla_uf sequencial

tempfile candidatos
save `candidatos'

!mkdir "output/bens_candidato"

foreach ano of numlist 2006(2)2020 {
	
	!mkdir "output/bens_candidato/ano=`ano'"
	
	use "output/bens_candidato_`ano'.dta", clear
	
	ren sequencial_candidato sequencial
	
	merge m:1 ano tipo_eleicao sigla_uf sequencial using `candidatos'
	drop if _merge == 2
	drop _merge
	
	ren sequencial sequencial_candidato
	
	order ano tipo_eleicao sigla_uf sequencial_candidato id_candidato_bd id_tipo_item tipo_item descricao_item valor_item
	
	tempfile bens
	save `bens'
	
	levelsof sigla_uf, l(ufs)
	foreach uf in `ufs' {
		!mkdir "output/bens_candidato/ano=`ano'/sigla_uf=`uf'"
		use `bens', clear
		keep if ano == `ano' & sigla_uf == "`uf'"
		drop ano sigla_uf
		export delimited "output/bens_candidato/ano=`ano'/sigla_uf=`uf'/bens_candidato.csv", replace
	}
}
*

//-------------------------------------------------//
// receitas - candidato
//-------------------------------------------------//

//--------------------//
// unifica header
//--------------------//

foreach ano of numlist 2002(2)2020 {
	
	use "output/receitas_candidato_`ano'.dta", clear
	
	keep in 1/10
	
	tempfile c`ano'
	save `c`ano''
	
}
*

use `c2002', clear
foreach ano of numlist 2004(2)2020 {
	append using `c`ano''
}
*
drop if _n >= 1
tempfile vazio
save `vazio'

//--------------------//
// merge com id_candidato
// particiona
//--------------------//

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 0
keep id_candidato_bd ano tipo_eleicao sigla_uf id_municipio_tse cargo numero

tempfile candidatos_mod0
save `candidatos_mod0'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo != "presidente"
keep id_candidato_bd ano tipo_eleicao sigla_uf cargo numero

tempfile candidatos_mod2_estadual
save `candidatos_mod2_estadual'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo == "presidente"
keep id_candidato_bd ano tipo_eleicao cargo numero

tempfile candidatos_mod2_presid
save `candidatos_mod2_presid'

!mkdir "output/receitas_candidato"

foreach ano of numlist 2002(2)2020 {
	
	!mkdir "output/receitas_candidato/ano=`ano'"
	
	use `vazio', clear
	append using "output/receitas_candidato_`ano'.dta"
	
	ren numero_candidato numero
	
	if mod(`ano', 4) == 0 {
		
		merge m:1 ano tipo_eleicao sigla_uf id_municipio_tse cargo numero using `candidatos_mod0'
		drop if _merge == 2
		drop _merge
		
	}
	else {
		
		preserve
			
			keep if cargo != "presidente"
			
			merge m:1 ano tipo_eleicao sigla_uf cargo numero using `candidatos_mod2_estadual'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_estadual
			save `resultados_mod2_estadual'
			
		restore
		preserve
			
			keep if cargo == "presidente"
			
			merge m:1 ano tipo_eleicao cargo numero using `candidatos_mod2_presid'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_presid
			save `resultados_mod2_presid'
			
		restore
		
		use `resultados_mod2_estadual', clear
		append using `resultados_mod2_presid'
		
	}
	*
	
	ren numero numero_candidato
	
	order ano turno tipo_eleicao sigla_uf id_municipio id_municipio_tse ///
		id_candidato_bd sequencial_candidato numero_candidato cpf_candidato cnpj_candidato titulo_eleitor_candidato nome_candidato cpf_vice_suplente numero_partido nome_partido sigla_partido cargo ///
		sequencial_receita data_receita fonte_receita origem_receita natureza_receita especie_receita situacao_receita descricao_receita valor_receita ///
		sequencial_candidato_doador cpf_cnpj_doador sigla_uf_doador id_municipio_tse_doador nome_doador nome_doador_rf cargo_candidato_doador numero_partido_doador sigla_partido_doador nome_partido_doador esfera_partidaria_doador numero_candidato_doador cnae_2_doador descricao_cnae_2_doador ///
		cpf_cnpj_doador_orig nome_doador_orig nome_doador_orig_rf tipo_doador_orig descricao_cnae_2_doador_orig ///
		nome_administrador cpf_administrador numero_recibo_eleitoral numero_documento numero_recibo_doacao numero_documento_doacao tipo_prestacao_contas data_prestacao_contas sequencial_prestador_contas cnpj_prestador_contas entrega_conjunto
	
	//--------------//
	// particiona
	//--------------//
	
	levelsof sigla_uf, l(ufs)
	foreach uf in `ufs' {
		
		!mkdir "output/receitas_candidato/ano=`ano'/sigla_uf=`uf'"
		
		preserve
			keep if ano == `ano' & sigla_uf == "`uf'"
			drop ano sigla_uf
			export delimited "output/receitas_candidato/ano=`ano'/sigla_uf=`uf'/receitas_candidato.csv", replace
		restore
		
	}
	
}
*

//-------------------------------------------------//
// despesas - candidato
//-------------------------------------------------//

//--------------------//
// unifica header
//--------------------//

foreach ano of numlist 2016 2020 { // 2002(2)2020 {
	
	use "output/despesas_candidato_`ano'.dta", clear
	
	keep in 1/10
	
	tempfile c`ano'
	save `c`ano''
	
}
*

use `c2016', clear
foreach ano of numlist 2020 { // 2004(2)2020 {
	append using `c`ano''
}
*
drop if _n >= 1
tempfile vazio
save `vazio'

//--------------------//
// merge com id_candidato
// particiona
//--------------------//

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 0
keep id_candidato_bd ano tipo_eleicao sigla_uf id_municipio_tse cargo numero

tempfile candidatos_mod0
save `candidatos_mod0'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo != "presidente"
keep id_candidato_bd ano tipo_eleicao sigla_uf cargo numero

tempfile candidatos_mod2_estadual
save `candidatos_mod2_estadual'

use "output/norm_candidatos.dta", clear

keep if mod(ano, 4) == 2 & cargo == "presidente"
keep id_candidato_bd ano tipo_eleicao cargo numero

tempfile candidatos_mod2_presid
save `candidatos_mod2_presid'

!mkdir "output/despesas_candidato"

foreach ano of numlist 2016 2020 { // 2002(2)2020 {
	
	!mkdir "output/despesas_candidato/ano=`ano'"
	
	use `vazio', clear
	append using "output/despesas_candidato_`ano'.dta"
	
	ren numero_candidato numero
	
	if mod(`ano', 4) == 0 {
		
		merge m:1 ano tipo_eleicao sigla_uf id_municipio_tse cargo numero using `candidatos_mod0'
		drop if _merge == 2
		drop _merge
		
	}
	else {
		
		preserve
			
			keep if cargo != "presidente"
			
			merge m:1 ano tipo_eleicao sigla_uf cargo numero using `candidatos_mod2_estadual'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_estadual
			save `resultados_mod2_estadual'
			
		restore
		preserve
			
			keep if cargo == "presidente"
			
			merge m:1 ano tipo_eleicao cargo numero using `candidatos_mod2_presid'
			drop if _merge == 2
			drop _merge
			
			tempfile resultados_mod2_presid
			save `resultados_mod2_presid'
			
		restore
		
		use `resultados_mod2_estadual', clear
		append using `resultados_mod2_presid'
		
	}
	*
	
	ren numero numero_candidato
	
	order ano turno tipo_eleicao sigla_uf id_municipio id_municipio_tse ///
		id_candidato_bd sequencial_candidato numero_candidato cpf_candidato nome_candidato cpf_vice_suplente numero_partido sigla_partido nome_partido cargo ///
		sequencial_despesa data_despesa tipo_despesa descricao_despesa origem_despesa valor_despesa ///
		tipo_prestacao_contas data_prestacao_contas sequencial_prestador_contas cnpj_prestador_contas ///
		tipo_documento numero_documento ///
		cpf_cnpj_fornecedor nome_fornecedor nome_fornecedor_rf cnae_2_fornecedor descricao_cnae_2_fornecedor ///
		tipo_fornecedor esfera_partidaria_fornecedor sigla_uf_fornecedor ///
		id_municipio_tse_fornecedor sequencial_candidato_fornecedor numero_candidato_fornecedor ///
		numero_partido_fornecedor sigla_partido_fornecedor nome_partido_fornecedor cargo_fornecedor
	
	//--------------//
	// particiona
	//--------------//
	
	levelsof sigla_uf, l(ufs)
	foreach uf in `ufs' {
		
		!mkdir "output/despesas_candidato/ano=`ano'/sigla_uf=`uf'"
		
		preserve
			keep if ano == `ano' & sigla_uf == "`uf'"
			drop ano sigla_uf
			export delimited "output/despesas_candidato/ano=`ano'/sigla_uf=`uf'/despesas_candidato.csv", replace
		restore
		
	}
	
}
*


