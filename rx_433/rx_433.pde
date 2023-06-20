/*
ver ::cl 20120520
Configuracion basica para modulo receptor  RR 10
Utiliza libreria VirtualWire.h
pin 01 5v
pin 02 Tierra
pin 03 antena externa
pin 07 tierra
pin 10 5v
pin 11 tierra
pin 12 5v
pin 14 Arduino pin digital 2
pin 15 5v
*/

#include <VirtualWire.h>
#include <string.h>

#define POLYNOMIAL 0x25 // Polinomio generador 100101

uint8_t crc5(uint8_t *data, uint8_t len) {
  uint8_t crc = 0;
  for (uint8_t i = 0; i < len; i++) {
    crc ^= data[i];
    for (uint8_t j = 0; j < 8; j++) {
      if (crc & 0x80)
        crc = (crc << 1) ^ POLYNOMIAL;
      else
        crc <<= 1;
    }
  }
  return crc & 0x1F; // Devuelve solo los 5 bits inferiores
}

const char* modificarString(const char* texto) {
  if (strlen(texto) == 1) {
    static char resultado[3];  // Crear un array lo suficientemente grande para almacenar el resultado
    strcpy(resultado, "0");
    strcat(resultado, texto);
    return resultado;
  } else {
    return texto;
  }
}

#include <string.h>

void dividirCadena(const char* cadena, char* primeraMitad, char* segundaMitad) {
  size_t longitud = strlen(cadena);
  size_t longitudPrimeraMitad = (longitud > 8) ? 8 : longitud;
  size_t longitudSegundaMitad = longitud - longitudPrimeraMitad;

  strncpy(primeraMitad, cadena, longitudPrimeraMitad);
  primeraMitad[longitudPrimeraMitad] = '\0';

  strncpy(segundaMitad, cadena + longitudPrimeraMitad, longitudSegundaMitad);
  segundaMitad[longitudSegundaMitad] = '\0';
}

bool estaEnLista(char elemento, const char* lista) {
  int longitud = strlen(lista);

  for (int i = 0; i < longitud; i++) {
    if (lista[i] == elemento) {
      return true;  // El elemento está en la lista
    }
  }

  return false;  // El elemento no está en la lista
}

int contarRepeticiones(const char* lista, char b) {
  int repeticiones = 0;
  int longitud = strlen(lista);

  for (int i = 0; i < longitud; i++) {
    if (lista[i] == b) {
      repeticiones++;
    }
  }

  return repeticiones;
}


//definicion de parametros del paquete
const char* origenA = "00"; //broadcast 
const char* origenB = "03"; //maybe somos el 6 xd
const char* crc;
const char* crcRecibido;
const char secuencia[] = {'1','2','3','4','5'};
const int s[] = {1,2,3,4,5};
const char total = "5"; 
char found[5]; 

bool primero = false;
bool error = false;
int anterior = 0;
bool encontrado = false;
const char* pri;
const char* msj;

//contar cuantos crc son buenos llegar contador en el if del ta weno
// static en loop
//llevar un contador que vaya checando la secuencia (si no son iguales significa que se perdio un paquete)



void setup(){
    Serial.begin(9600);
    vw_set_ptt_inverted(true); 
    vw_setup(2000);
    vw_set_rx_pin(2);
    vw_rx_start();
}

void loop() {
  error = false;
  static int contador = 0;
  static int cocrc = 0;

  uint8_t buf[VW_MAX_MESSAGE_LEN];
  uint8_t buflen = VW_MAX_MESSAGE_LEN;
  
  if (vw_get_message(buf, &buflen)) {
    char m[VW_MAX_MESSAGE_LEN + 1];
    int i;
    int pl;
    digitalWrite(13, HIGH);

    for (i = 0; i < buflen; i++) {
      m[i] = (char) buf[i];
      //Serial.println(buf[i]);

    }
    m[i+1] = '\0';

    m[buflen] = '\0';


    digitalWrite(13, LOW);

  
    if(m[6] == '1'){
      primero = true;
    }

    if (((m[0] == origenA[0] && m[1] == origenA[1])||(m[0] == origenB[0] && m[1] == origenB[1]))&&primero){ 
      //trabajar broadcast || unicast
      char primeraMitad[9];  // Suficiente espacio para 8 caracteres + 1 carácter nulo adicional
      char segundaMitad[9];  // Suficiente espacio para 8 caracteres + 1 carácter nulo adicional
      dividirCadena(m, primeraMitad, segundaMitad);
      Serial.println(primeraMitad);
      Serial.println(segundaMitad);
      for (int i = 0;found[i] !='\0';i++){
        if(found[i] == primeraMitad[6]){
          encontrado = true;
          break;
        }
      }
      if(encontrado == false){
        found[contador] = primeraMitad[6];
      }
      
      //Serial.println(primeraMitad[6]);
      //Serial.println(secuencia[contador]);
      //Serial.println("aqui");
      //Serial.println(secuencia[contador]);

      //miArreglo[contador]  = atoi(primeraMitad[6]);

      if((primeraMitad[6] != secuencia[contador]) || secuencia[contador] == '5' || encontrado){
        

        int intValor = primeraMitad[6] - '0';
        
        //Serial.println(intValor);
        int ce = secuencia[contador] - '0';
        //Serial.println(ce);
        pl = 5 - ce;
        if(encontrado){
          pl += 1;
          ce -=1;
        }
        
        primero = false;
        error = true;
        
        Serial.print("paquetes recibidos: ");
        Serial.println(ce);
        Serial.print("paquetes perdidos: ");
        Serial.println(pl);


        
        
//        delay(1000);
      }


      uint8_t mycrc = crc5((uint8_t *)segundaMitad, strlen(segundaMitad));
      //mycrc += 1;
      char charCrc[3];
      sprintf(charCrc, "%u", mycrc);
      const char* charValor = modificarString(charCrc); // validar y/o corregir longitud de crc (2 bytes)

          
      if(charValor[0] == primeraMitad[4] && charValor[1] == primeraMitad[5]){ //valida el crc
        msj = segundaMitad;
        Serial.println(msj);
        cocrc+=1;

        //Serial.println(msj);

        }       
    

      contador += 1;
      if(contador > 4 || error){
        Serial.print("crc correctos: ");
        Serial.println(cocrc);
        contador = 0;
        cocrc = 0;
        primero = false;
        for(int i = 0;i<=5;i++){
          found[i] = '\0';
        }
        encontrado = false;

      }
    //Serial.println("final: ");
    //Serial.println(contador);

    }
    else{
    }
    
    buflen = VW_MAX_MESSAGE_LEN;  // Actualizar buflen para la siguiente recepción de mensaje
  }

  else{
    //
  }

  delay(1000);
  buflen = VW_MAX_MESSAGE_LEN;  // Actualizar buflen para la siguiente recepción de mensaje
}








