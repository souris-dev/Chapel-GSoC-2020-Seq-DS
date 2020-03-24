use UnitTest;
use UnrolledLinkedList;

proc testAppendsAndOperators(test: borrowed Test) throws
{
    var ull = new UnrolledLinkedList(int, 3);
    ull.append(1);
    ull.append(2, 3);
    ull.append(4);

    writeln("Contents of ull: ");
    writeln(ull);
    
    test.assertEqual(ull[1], 1);
    test.assertEqual(ull.first(), 1);
    test.assertEqual(ull.last(), 4);

    test.assertEqual(ull[2], 2);

    ull.clear();

    writeln("List after clearing: ");
    writeln(ull);

    ull.append(1);
    ull.append(2, 3);
    ull.append(4);

    test.assertTrue(ull.contains(3));
    test.assertFalse(ull.contains(8));

    test.assertEqual(ull.size, 4);

    var ull2 = new UnrolledLinkedList(int, 3);
    ull2.push_back(1, 2, 3, 4);

    test.assertTrue(ull == ull2);

    ull2.clear();
    ull2.append(6, 5);

    writeln("List ull2: ", ull2);

    test.assertEqual(ull2[1], 6);
    test.assertEqual(ull2[2], 5);

    test.assertEqual(ull2.first(), 6);
    test.assertEqual(ull2.last(), 5);

    ull2 = ull;
    test.assertEqual(ull2.size, 4);
    
    for i in 1..4 do
        test.assertEqual(ull[i], ull2[i]);

    ull2.insertNear(3, 8);
    writeln(ull2);

    test.assertEqual(ull2.find(8), 8);

    writeln("Now, ull: ", ull);
    writeln("Now, ull2: ", ull2);
    ull.extend(ull2);
    writeln("Entended ull: ");
    writeln(ull);

    test.assertTrue(ull != ull2);
    test.assertFalse(ull == ull2);

    var count = 1;
    for i in ull {
        test.assertEqual(ull[count], i);
        count += 1;
    }
}

proc testDeletions(test: borrowed Test) throws
{
    var ull = new UnrolledLinkedList(int, 3);
    ull.append(1, 2, 3, 4);
    writeln(ull);

    test.assertEqual(ull.pop(), 4);
    writeln(ull);
    ull.append(5, 6, 7);
    
    writeln(ull);
    test.assertEqual(ull.pop(), 7);

    writeln(ull);

    ull.deleteItem(8); // 8 doesn't exist in ull, should do nothing
    ull.deleteItem(2);

    writeln("After deleting 2: ", ull);

    test.assertEqual(ull.pop(), 6);
    test.assertEqual(ull.pop(), 5);
    test.assertEqual(ull.pop(), 3);

    ull.append(3, 5, 6, 7);
    writeln(ull);

    ull.deleteItem(5);
    writeln("After deleting 5: ", ull);

    test.assertEqual(ull.pop(), 7);
    writeln(ull);
    test.assertEqual(ull.pop(), 6);
    writeln(ull);
    test.assertEqual(ull.pop(), 3);
    writeln(ull);
    test.assertEqual(ull.pop(), 1);
    writeln(ull);
    
    ull.append(1, 2, 3, 4);

    test.assertEqual(ull.pop(), 4);
    ull.append(5, 6, 7);

    ull.insertNear(3, 10); //
    ull.insertNear(3, 11); //

    writeln(ull);

    ull.deleteItem(5); //
    writeln(ull);
}

UnitTest.main();