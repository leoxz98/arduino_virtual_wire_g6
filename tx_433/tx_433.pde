/*
ver ::cl 20120520
Configuracion basica para modulo transmisor RT 11
Utiliza libreria VirtualWire.h
pin 01 entrada desde Arduino pin digital 2
pin 02 Tierra
pin 07 tierra
pin 08 antena externa
pin 09 tierra
pin 10 5v
*/
#include <VirtualWire.h>
#include <string.h>

const char* concatenar(const char* A, const char* B) {
    size_t lenA = strlen(A);
    size_t lenB = strlen(B);

    char* resultado = new char[lenA + lenB + 1]; // +1 para el carácter nulo adicional
    strcpy(resultado, A);
    strcat(resultado, B);

    return resultado;
}




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

char* concatenarParametros(const char* origen, const char* destino, const char* crc, const char* secuencia, const char* total,const char* mensaje) {
  // Calcular la longitud total del string resultante
  size_t longitudTotal = strlen(origen) + strlen(destino) + strlen(crc) + strlen(secuencia) + strlen(total) + strlen(mensaje) + 1;  // +1 para el carácter nulo

  // Crear un array lo suficientemente grande para contener el string resultante
  char* resultado = new char[longitudTotal];

  // Concatenar los parámetros en orden de aparición
  strcpy(resultado, origen);
  strcat(resultado, destino);
  strcat(resultado, crc);
  strcat(resultado, secuencia);
  strcat(resultado, total);
  strcat(resultado,mensaje);

  return resultado;
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



//definicion de parametros del paquete
const char* origen = "06";
const char* destino = "06";
const char* crc;
const char* secuencia[] = {"1","2","3","4","5"};
const char* total = "5";  



void setup(){
    vw_set_ptt_inverted(true);
    vw_setup(2000);
    vw_set_tx_pin(2);    
    Serial.begin(9600);
    Serial.println("configurando envio");
}

void loop(){
  //definir msj (max 8 de largo, si no es asi poner espacios hasta 8)
  char *msg = "G 06";
  int lenmsj = strlen(msg);
  Serial.println(lenmsj);
  //calcular crc del msj
  uint8_t resultCrc = crc5((uint8_t *)msg, strlen(msg));
  //resultCrc += 1;
  char strCrc[4];  
  itoa(resultCrc, strCrc, 10); // pasar a str el crc
  crc = modificarString(strCrc);
  Serial.println("crc:");
  Serial.println(crc);
  

  //char* partOne = concatenarParametros(origen,destino,crc,"1",total);

  //envio de los 5 paquetes

  for (int i = 0; i < 5; i++){
    char* partOne = concatenarParametros(origen,destino,crc,secuencia[i],total,msg);

    vw_send((uint8_t *)partOne, strlen(partOne));
    vw_wait_tx();
    // esparamos a que el receptor verifique que es su destino = receptor
    Serial.println("enviado paquete:");
    Serial.println(partOne);
    delay(1000);
    
  }
  Serial.println("en espera para mandar:");
       
}
