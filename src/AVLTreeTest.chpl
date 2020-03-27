use UnitTest;
use AVLTree;

proc testInserts(test: borrowed Test) throws
{
    var avltree = new AVLTree(int);
    avltree.push(10);
    avltree.push(20);
    avltree.push(30);
    avltree.push(40);
    avltree.push(50);
    avltree.push(25);

    writeln(avltree);
}

UnitTest.main();