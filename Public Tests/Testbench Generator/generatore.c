/*
 * Created by Lorenzo Guerrieri
 * Last change: 24/01/2021
*/


#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <math.h>


#define MAX_TEST_PER_FILE 10000


void generateTestCases();
void generateFromFile();
void generateFromConsole();
void generateRandomImage();
int rand_lim(int limit);
void loadMatrixFromConsole();
void loadMatrixFromFile(FILE* matrixFile);
void solve();
void createInData(FILE* outData);
void createResult(FILE* outResult);
void createReadable(FILE* outReadable);


unsigned int** image = NULL;
unsigned int** solution = NULL;
char testName[200];
int rows, columns;
int maxRows, minRows;
int maxColumns, minColumns;
int maxPixel, minPixel;

int main() {
    srand((unsigned int) time(NULL));
    printf("Choose a generation option:\n");
    options:
    printf("   1 - Generate random test cases\n");
    printf("   2 - Generate test cases from matrix file\n");
    printf("   3 - Generate test cases from manually inserted matrix\n");
    int choice;
    scanf("%d", &choice);

    if(choice == 1)
        generateTestCases();
    else if(choice == 2)
        generateFromFile();
    else if(choice == 3)
        generateFromConsole();
    else {
        printf("invalid option\n");
        goto options;
    }
}

void generateTestCases(){
    printf("Insert the minimum and maximum number of rows:\n");
    printf("[Format: min-max]: ");
    scanf("%d-%d", &minRows, &maxRows);

    printf("Insert the minimum and maximum number of columns:\n");
    printf("[Format: min-max]: ");
    scanf("%d-%d", &minColumns, &maxColumns);

    printf("Insert the minimum and maximum values allowed for each pixel:\n");
    printf("[Format: min-max]: ");
    scanf("%d-%d", &minPixel, &maxPixel);

    int testNumber;
    printf("Insert the number of tests to be generated:\n");
    scanf("%d", &testNumber);

    char split = 'n';
    if(testNumber > MAX_TEST_PER_FILE){
        printf("The number of test required is high and the result file might not be opened and/or edited by other programs."
               "\nNote that Vivado will still be able to use the file for testing, but the simulation folder might become very heavy.\n");
        do{
            printf("Do you want to split the output file in multiple files? [y/n]\n");
            scanf("%*c%c", &split);
        }while(split != 'y'  &&  split != 'Y'  &&  split != 'n'  &&  split != 'N');
    }

    FILE* ramData = fopen("ramData1.txt", "w");
    FILE* ramResult = fopen ("ramResult1.txt", "w");
    FILE* test = fopen("test1.txt", "w");

    int prevTest = 1;
    for(int i = 1; i <= testNumber; i++) {
        if((split == 'y'  ||  split == 'Y') && i-prevTest >= MAX_TEST_PER_FILE){
            prevTest = i;
            fclose(ramData);
            fclose(ramResult);
            fclose(test);

            int numLength = (int)((ceil(log10(i))+1)*sizeof(char));
            char dataFileName[20+numLength];
            char resultFileName[20+numLength];
            char testFileName[20+numLength];

            sprintf(dataFileName, "ramData%d.txt", i);
            sprintf(resultFileName, "ramResult%d.txt", i);
            sprintf(testFileName, "test%d.txt", i);

            ramData = fopen(dataFileName, "w");
            ramResult = fopen(resultFileName, "w");
            test = fopen(testFileName, "w");

            if(ramData == NULL  ||  ramResult == NULL  ||  test == NULL){
                printf("An error occurred while trying to create a file.\n");
                exit(-1);
            }
        }

        printf("Starting Test %d\n", i);

        generateRandomImage();

        solve();

        createInData(ramData);

        createResult(ramResult);

        sprintf(testName, "%d", i);
        createReadable(test);

        printf("Ended Test %d\n", i);
    }
}

void generateFromFile(){
    printf("Insert the matrix file path:\n");
    char path[200];
    scanf("%s", path);

    FILE* matrixFile = fopen(path, "r");
    FILE* ramData = fopen("ramData1.txt", "w");
    FILE* ramResult = fopen ("ramResult1.txt", "w");
    FILE* test = fopen("test1.txt", "w");

    while(!feof(matrixFile)){
        loadMatrixFromFile(matrixFile);

        printf("Starting test: %s\n", testName);

        solve();

        createInData(ramData);

        createResult(ramResult);

        createReadable(test);

        printf("Ended test: %s\n", testName);

        for(int i = 0; i < columns; i++){
            free(image[i]);
        }
        free(image);
    }
}

void generateFromConsole(){
    FILE* ramData = fopen("ramData1.txt", "w");
    FILE* ramResult = fopen ("ramResult1.txt", "w");
    FILE* test = fopen("test1.txt", "w");

    char choice;
    do{
        loadMatrixFromConsole();
        solve();
        createInData(ramData);
        createResult(ramResult);
        createReadable(test);

        question:
        printf("Do you want to insert another matrix? [y/n]\n");
        scanf("%*c%c", &choice);
        if(!(choice == 'y'  ||  choice == 'Y'  ||  choice == 'n'  ||  choice == 'N'))
            goto question;
    }while(choice == 'y'  ||  choice == 'Y');
}

int rand_lim(int limit) {
/* return a random number between 0 and limit inclusive.
 */

    int divisor = RAND_MAX/(limit+1);
    int returnValue;

    do {
        returnValue = rand() / divisor;
    } while (returnValue > limit);

    return returnValue;
}

void generateRandomImage(){
    rows = rand_lim(maxRows-minRows)+minRows;
    columns = rand_lim(maxColumns-minColumns)+minColumns;
    image = malloc(sizeof(unsigned int*)*columns);
    for(int i = 0; i < columns; i++){
        image[i] = malloc(sizeof(unsigned int)*rows);
    }

    for(int y = 0; y < rows; y++){
        for(int x = 0; x < columns; x++){
            image[x][y] = rand_lim(maxPixel-minPixel)+minPixel;
        }
    }
}

void loadMatrixFromConsole(){
    printf("Insert a name for the test:\n");
    scanf("%*c%[^\n]%*c", testName);

    printf("Insert the number of rows and lines:\n");
    printf("[Format: rows-columns]: ");
    scanf("%d-%d", &rows, &columns);

    image = malloc(sizeof(unsigned int *)*columns);
    for(int i = 0; i < columns; i++){
        image[i] = malloc(sizeof(unsigned int)*rows);
    }

    printf("Insert each row of the matrix with the values divided by a space:\n");
    for(int y = 0; y < rows; y++){
        for(int x = 0; x < columns-1; x++){
            scanf("%d ", &image[x][y]);
        }
        scanf("%d", &image[columns-1][y]);
    }

}

void loadMatrixFromFile(FILE* matrixFile){
    fscanf(matrixFile, "%s", testName);
    fscanf(matrixFile, "%d-%d", &rows, &columns);

    image = malloc(sizeof(unsigned int*)*columns);
    for(int i = 0; i < columns; i++){
        image[i] = malloc(sizeof(unsigned int)*rows);
    }

    for(int y = 0; y < rows; y++){
        for(int x = 0; x < columns-1; x++){
            fscanf(matrixFile, "%3d ", &image[x][y]);
        }
        fscanf(matrixFile, "%3d", &image[columns-1][y]);
    }
}

void createInData(FILE* outData){
    if(outData == NULL) {
        printf("%d\n", rows);
        printf("%d\n", columns);
    }else {
        fprintf(outData, "%d\n", rows);
        fprintf(outData, "%d\n", columns);
    }

    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            if(outData == NULL)
                printf("%d\n", image[x][y]);
            else
                fprintf(outData, "%d\n", image[x][y]);
        }
    }
}

void solve(){
    solution = malloc(sizeof(unsigned int*)*columns);
    for(int i = 0; i < columns; i++){
        solution[i] = malloc(sizeof(unsigned int)*rows);
    }

    unsigned int min = 255;
    unsigned int max = 0;
    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            if (image[x][y] < min)
                min = image[x][y];
            if (image[x][y] > max)
                max = image[x][y];
        }
    }

    unsigned int delta = max-min;
    unsigned int shift;

    if(delta == 0)
        shift = 8;
    else if(delta <= 2)
        shift = 7;
    else if(delta <= 6)
        shift = 6;
    else if(delta <= 14)
        shift = 5;
    else if(delta <= 30)
        shift = 4;
    else if(delta <= 62)
        shift = 3;
    else if(delta <= 126)
        shift = 2;
    else if(delta <= 254)
        shift = 1;
    else
        shift = 0;

    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            unsigned int tempPixel = (image[x][y]-min) << shift;
            if(tempPixel < 255)
                solution[x][y] = tempPixel;
            else
                solution[x][y] = 255;
        }
    }
}

void createResult(FILE* outResult){
    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            if(outResult == NULL)
                printf("%d\n", solution[x][y]);
            else
                fprintf(outResult, "%d\n", solution[x][y]);
        }
    }
}

void createReadable(FILE* outReadable){
    if(outReadable == NULL) {
        printf("TEST: %s\n", testName);
        printf("Rows: %d    Columns: %d\n\n", rows, columns);
        printf("Image\n");
    }else {
        fprintf(outReadable, "TEST: %s\n", testName);
        fprintf(outReadable, "Rows: %d    Columns: %d\n\n", rows, columns);
        fprintf(outReadable, "Image\n");
    }


    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            if(outReadable == NULL)
                printf("%3d ", image[x][y]);
            else
                fprintf(outReadable, "%3d ", image[x][y]);
        }
        if(outReadable == NULL)
            printf("\n");
        else
            fprintf(outReadable, "\n");
    }

    if(outReadable == NULL) {
        printf("\nSolution\n");
    }else {
        fprintf(outReadable, "\nSolution\n");
    }

    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            if(outReadable == NULL)
                printf("%3d ", solution[x][y]);
            else
                fprintf(outReadable, "%3d ", solution[x][y]);
        }
        if(outReadable == NULL)
            printf("\n");
        else
            fprintf(outReadable, "\n");
    }

    if(outReadable == NULL)
        printf("\n\n");
    else
        fprintf(outReadable, "\n\n");

}


/*
 * Created by Lorenzo Guerrieri
 * Last change: 24/01/2021
*/