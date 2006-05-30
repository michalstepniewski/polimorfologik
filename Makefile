#Makefile do tworzenia s�ownika morfologicznego
#pliki:
#afiksy - plik ze specyfikacj�, kt�ra flaga ispella odpowiada za okre�lony wyraz
#formy.txt - plik s�ownika: wyraz - flagi i ko�c�wki ispella
#odm.txt - aktualny s�ownik z witryny www.kurnik.pl/slownik (s�ownik odmian)
#pl_PL.aff - aktualny plik ze s�ownika myspell z witryny kurnik.pl
#pojedyncze.txt - wyrazy nieodmienne
#nieregularne.txt - odmiany nieregularne
#slownik_regularny - s�ownik morfologiczny odmian regularnych, generowany
#morph_base_join.txt - wygenerowana baza morfologiczna (odwzorowanie flagi i ko�c�wki ispella -> oznaczenia morfosyntaktyczne)
#baza_nieodmiennych.txt - wyrazy z r�cznie dobranymi anotacjami

afiksy:
	./build A
	./ispell -e2 -d ./polish <A >afiksy.txt
formy:
	gawk -f aff3.awk afiksy.txt >formy.txt
	gawk -f forma_pdst.awk A >formy_pdst.txt 
lacz:
	cat formy.txt formy_pdst.txt | sort -u > formy_ost.txt
slownik:
#slownik regularny
	gawk -f morpher.awk formy_ost.txt >slownik_regularny.txt
#przygotowanie form nieregularnych 
	gawk -f nietypowe.awk A >bez_flag.txt
	gawk -f spr_bez_flag.awk bez_flag.txt >slownik_nieodm.txt
	gawk -f dopisane.awk odm.txt >nieregularne.txt
	gawk -f anot_niereg.awk nieregularne.txt > slownik_niereg.txt
#po��czenie
	cat slownik*.txt | sort -u > morfologik.txt

fsa:
	gawk -f morph_data.awk morfologik.txt | ./fsa_ubuild -O -o polish.dict
	
all:
	afiksy
	formy
	slownik

test:
#formy_ht_3.txt - plik testowy
	gawk -f compare.awk formy_ht_3.txt >konflikty.txt

clean:
	rm formy*.txt
	rm bez_flag.txt
	rm slownik*.txt
	rm nieregularne.txt
	rm afiksy.txt