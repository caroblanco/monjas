class Jugador{
	const color
	const mochila = []
	var nivelSospecha = 40
	const tareas = []
	const completadas = []
	var impugnado = false
	
	method nivelSospecha() = nivelSospecha
	
	method tieneMochilaVacia() = mochila.isEmpty()

	method esSospechoso() = nivelSospecha > 50
	
	method buscarItem(item){
		mochila.add(item)
	}
	
	method usarItem(item){
		mochila.remove(item)
	}
	
	method tiene(item) = mochila.contains(item)
	
	method agregarSospecha(cant){
		nivelSospecha += cant
	}
	
	method disminuirSospecha(cant){
		nivelSospecha -= cant
	}
	
	method realizarCualquierPendiente() = tareas.anyOne().realizar(self)
	
	method llamarVotEmergencia(){
		nave.comenzarVot()
	}
	
	method votarEnBlanco(){
		impugnado = true
	}
	
	method votar(jugadores){
		if(impugnado){
			nave.agregarVoto("enBlanco")
			impugnado = false
		}else{
			const voto = self.criterioTipo(jugadores)
			nave.agregarVoto(voto)
		}
	}
	
	method criterioTipo(jugadores)
}

class Tripulante inherits Jugador{
	var personalidad
	override method criterioTipo(jugadores) =  personalidad.votacion(jugadores)
	
	method realizarTarea(tarea){
		self.puedeRealizarTarea(tarea)
		self.realizar(tarea)
		self.informarNave()
	}
	
	method realizar(tarea){
		tarea.realizar(self)
			tareas.remove(tarea)
			completadas.add(tarea)
	}
	
	method informarNave(){
		nave.chequearTareas()
	}
	
	method puedeRealizarTarea(tarea){
		if(not tareas.contains(tarea) || not tarea.cumpleRestricciones(self)){
			self.error("NO SE PUEDE REALIZAR")
		}
	}
	
	method todasTareasCompletadas() = tareas.isEmpty()
	
}

class Impostor inherits Jugador{
	method realizarTarea(tarea){}
	method todasTareasCompletadas() = true
	
	method realizarSabotaje(sabotaje){
		sabotaje.realizarSabotaje(self)
	}
	
	override method criterioTipo(jugadores) = jugadores.anyOne()

}

//////////////////////////////////////////////////////////////////////////////////////////////////

object nave{
	const jugadores = impostores + tripulantes
	var impostores = []
	var tripulantes = []
	var oxigeno = 100
	const votos = []
	const vivos = tripulantes
	
	method subirOxigeno(cant){
		oxigeno += cant
	}
	
	method bajarOxigeno(cant){
		oxigeno -= cant
		self.oxigenoEnCero()
	}
	
	method oxigenoEnCero(){
		if(oxigeno == 0){
			self.ganoImp()
		}
	}
	method todasTareasCompletas() = jugadores.all({unJ => unJ.todasTareasCompletadas()})
	
	method chequearTareas(){
		if(self.todasTareasCompletas()){
			self.ganoTrip()
		}
	}
	
	method algunoTiene(algo) = jugadores.any({unT => unT.tiene(algo)})
	
	method comenzarVot(){
		vivos.forEach({unJ => unJ.votar(jugadores)})
		self.contarVotos()
	}
	
	method contarVotos(){
		const masVot = self.masVotado()
		if( masVot != "enBlanco"){
			self.expulsarJugadorMasVotado(masVot)
		}
	}
	
	method agregarVoto(voto){
		votos.add(voto)
	}
	
	method masVotado() = votos.max({unV => votos.occurrencesOf(unV)})
	
	method expulsarJugadorMasVotado(masVot){
		self.expulsarJugador(masVot)
		
	}
	
	method expulsarJugador(alguien){
		vivos.remove(alguien)
		self.chequearGanadores()
	}
	
	method chequearGanadores(){
		if(self.noHayImpostores()){
			self.ganoTrip()
		}else if(self.gananImpostores()){
			self.ganoImp()
		}
	}
	
	method noHayImpostores() = jugadores.intersection(impostores).isEmpty()
	
	method gananImpostores() = jugadores.intersection(tripulantes).size() == impostores.size() 
	
	method ganoTrip(){
		self.error("GANARON LOS TRIPULANTES")
	}
	method ganoImp(){
		self.error("GANARON LOS IMPOSTORES")
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////

object arreglarTablero{
	
	method cumpleRestricciones(tripulante) = tripulante.tiene("llave inglesa")
	
	method realizar(tripulante){
		tripulante.agregarSospecha(10)
	}
}

object sacarBasura{
	method cumpleRestricciones(tripulante) = ["escoba","bolsa de basura"].forAll({unO => tripulante.tiene(unO)})//tripulante.tiene("escoba") && tripulante.tiene("bolsa de consorcio")
	
	method realizar(tripulante){
		tripulante.disminuirSospecha(4)
	}
}

object ventilarNave{
	
	method cumpleRestricciones(tripulante) = true
	
	method realizar(tripulante){
		nave.subirOxigeno(5)
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Sabotaje{
	method realizarSabotaje(impostor){
		impostor.aumentarSospecha(5)
		self.consecuenciaParticular()
	}
	
	method consecuenciaParticular(){}
}

object reducirOxigeno inherits Sabotaje{
	override method consecuenciaParticular(){
		if(not nave.algunoTiene("tubo de oxigeno")){
			nave.bajarOxigeno(10)
		}
	}
}

class ImpugnarAJugador inherits Sabotaje{
	const jugador
	
	override method consecuenciaParticular(){
		self.obligarVotoBlanco()
	}
	
	method obligarVotoBlanco(){
		jugador.votarEnBlanco()
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////

class Personalidad{
	method votacion(jugadores) = jugadores.findOrDefault(self.cumpleCondicion(jugadores).anyOne(),"enBlanco")
	
	method cumpleCondicion(jugadores)
}


object troll inherits Personalidad{
	override method cumpleCondicion(jugadores) = jugadores.filter({unJ => not unJ.esSospechoso()})
}

object detective inherits Personalidad{
	override method votacion(jugadores) = jugadores.max({unJ => unJ.nivelSospecha()})
	override method cumpleCondicion(jugadores){}
}

object materialista inherits Personalidad{
	override method cumpleCondicion(jugadores) = jugadores.filter({unJ => unJ.tieneMochilaVacia()})
}