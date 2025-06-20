# Introduzione

Questo repository contiene un'implementazione del **Gioco del 100** scritta in assembly (NASM).

Il codice presente in questo repository è stato scritto durante le riprese del video [**CA-25-010**](https://youtu.be/YdUoIxVNeKI) del canale YouTube [AFK](https://www.youtube.it/@valerio_afk).

* 📹 [Link al video](https://youtu.be/YdUoIxVNeKI)

# Guida all'utilizzo

## Prerequisiti
* Computer con processore x86-64 bit.
* Sistema operativo Linux (o qualsiasi altro OS UNIX/UNIX-like che segue la System V ABI Convention).
* NASM.
* GCC (anche clang dovrebbe andare bene, anche se non testato).

## Compilazione

```sh
$ nasm -f elf64 -g gioco100.asm -o gioco100.o 
$ gcc -g gioco100.o -no-pie -o gioco100
$ ./gioco100
```

## Dimensione griglia & posizione iniziale

* Cambiare riga #5 per modificare la dimensione della griglia.
* Cambiare riga #6 per impostare una nuova posizione iniziale (formato riga,colonna).


# Contatti

Lasciate un commento al video è un ottimo modo per domande generiche. Domande specifiche sono incorragiate via e-mail, presente nella sezione `Informazioni` sul canale.

# Licence Agreement

The code in this repository is released under the terms of [GNU GPLv3 Licence Agreement](https://www.gnu.org/licenses/gpl-3.0.html). A summary of this (and other FOSS licences is provided [here](https://en.wikipedia.org/wiki/Comparison_of_free_and_open-source_software_licenses)).

# Disclaimer

The code provided in this repository is provided AS IS and is intended for educational purposes only.

From the MIT License

`THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE`

![GPLv3](https://img.shields.io/badge/license-GPLv3-brightgreen) ![Python 3.9](https://img.shields.io/badge/python-3.9-blue) ![PyGame 2.3](https://img.shields.io/badge/pygame-2.3-green)

[![Instagram Profile](https://img.shields.io/badge/Instagram-%40valerio__afk-ff69b4)](https://www.instagram.com/valerio_afk/) [![YouTube Channel](https://img.shields.io/badge/YouTube-%40valerio__afk-red)](https://www.youtube.it/@valerio_afk)

