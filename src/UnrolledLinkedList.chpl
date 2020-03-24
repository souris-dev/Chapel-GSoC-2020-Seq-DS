/* module UnrolledLinkedList: Provides implementation for UnrolledLinkedList */
/* By default, UnrolledLinkedList is not parallel-safe */

module UnrolledLinkedList
{
    private use List;

    pragma "no doc"
    class UnrolledLinkedListNode
    {
        type dataType;
        var numberOfItems: int = 0;
        var data: list(dataType);
        var next: unmanaged UnrolledLinkedListNode(dataType)?;

        proc init(type datType) 
        {
            dataType = datType;
            next = nil;
        }
    }

    /* ListEmptyError: thrown when pop is called on an empty list */
    class ListEmptyError : Error
    {
        proc init() {
            /* Empty */
        }
    }

    proc =(ref UnrolledLinkedList1: UnrolledLinkedList(?t1), const ref UnrolledLinkedList2: UnrolledLinkedList(?t2))
    {
        UnrolledLinkedList1.destroy();
        UnrolledLinkedList1.numberOfElementsInEachNode = UnrolledLinkedList2.numberOfElementsInEachNode;

        for item in UnrolledLinkedList2 do
            UnrolledLinkedList1.append(item);
    }

    /* == overload for ULL */
    /* 2 ULLS are equal if and only if their size, numberOfElementsInEachNode and elements are equal in same order */
    proc ==(ref UnrolledLinkedList1: UnrolledLinkedList(?t1), ref UnrolledLinkedList2: UnrolledLinkedList(?t2))
    {
        var equal = true;

        if (UnrolledLinkedList1.size != UnrolledLinkedList2.size) {
            return false;
        }

        if (UnrolledLinkedList1.numberOfElementsInEachNode != UnrolledLinkedList2.numberOfElementsInEachNode) {
            return false;
        }

        for i in 1..UnrolledLinkedList1.size {
            if (UnrolledLinkedList1[i] != UnrolledLinkedList2[i]) {
                equal = false;
                return false;
            }
        }
        return equal;
    }

    proc !=(ref UnrolledLinkedList1: UnrolledLinkedList(?t1), ref UnrolledLinkedList2: UnrolledLinkedList(?t2))
    {
        return !(UnrolledLinkedList1 == UnrolledLinkedList2);
    }

    /* Note: An UnrolledLinkedList can store only one type of elements */
    record UnrolledLinkedList
    {
        type dataType;
        var size: int = 0;
        var numberOfElementsInEachNode: int;
        var head: unmanaged UnrolledLinkedListNode(dataType)?;
        var tail: unmanaged UnrolledLinkedListNode(dataType)?;

        proc init(type datType, numElemInEachNode: int)
        {
            this.dataType = datType;
            this.numberOfElementsInEachNode = numElemInEachNode;
            this.head = nil;
            this.tail = nil;
        }

        /* Iterate over the ULL */
        iter these()
        {
            var temp = head;

            while (temp != nil)
            {
                for item in temp!.data do
                    yield item;

                temp = temp!.next;
            }
        }

        proc append(item: dataType)
        {
            if (head == nil)
            {
                head = new unmanaged UnrolledLinkedListNode(dataType);
                head!.data.append(item);
                head!.numberOfItems += 1;
                tail = head;

                this.size += 1;
                return;
            }

            if (tail!.numberOfItems < numberOfElementsInEachNode)
            {
                tail!.data.append(item);
                tail!.numberOfItems += 1;
            }
            else
            {
                var node = new unmanaged UnrolledLinkedListNode(dataType);
                
                // put last half of elements of tail into new node
                var n: int = tail!.numberOfItems;
                var midInd: int = if n % 2 == 1 then n/2 + 1 else n/2;

                // In chapel, list index starts from 1
                for i in (midInd + 1)..n
                {
                    node!.data.append(tail!.data[i]);
                    node!.numberOfItems += 1;
                }

                node!.data.append(item);
                node!.numberOfItems += 1;

                // remove the last half elements from tail
                for i in (midInd + 1)..n do
                    tail!.data.pop();

                tail!.numberOfItems = midInd;

                tail!.next = node;
                tail = node;
            }

            size += 1;
        }

        /* append() for multiple items */
        proc append(item: dataType, items: dataType ...?k)
        {
            this.append(item);
            for i in 1..k do
                this.append(items(i));
        }

        /*  Insert item in the node that has the item at position 'at', or the next if that node is full
        at is 1-based index 
        Throws ListEmptyError if list is empty when called 
        Returns false if at > size or unsuccessful
        Returns true if successfully inserted */
        proc insertNear(at: int, item: dataType): bool throws
        {
            var temp = head;

            if (head == nil)
            {
                throw new owned ListEmptyError();
                return false;
            }

            if (at > size)
            {
                return false;
            }
            
            if (at == size)
            {
                append(item);
                return true;
            }

            var count = 0;
            var reached = false;

            while (temp != nil)
            {
                for i in temp!.data
                {
                    count += 1;
                    if (count == at) {
                        reached = true;
                        break;
                    }
                }
                if (reached) {
                    break;
                }
                
                temp = temp!.next;
            }

            if (temp!.numberOfItems < numberOfElementsInEachNode)
            {
                temp!.data.append(item);
                temp!.numberOfItems += 1;
            }

            else
            {
                var node = new unmanaged UnrolledLinkedListNode(dataType);
                
                var n: int = temp!.numberOfItems;
                var midInd: int = if n % 2 == 1 then n/2 + 1 else n/2;

                // In chapel, list index starts from 1
                for i in (midInd + 1)..n
                {
                    node!.data.append(temp!.data[i]);
                    node!.numberOfItems += 1;
                }

                node!.data.append(item);
                node!.numberOfItems += 1;

                for i in (midInd + 1)..n do
                    temp!.data.pop();

                temp!.numberOfItems = midInd;

                node!.next = temp!.next;
                temp!.next = node;
            }

            size += 1;
            return true;
        }

        /* Another name for append() */
        inline proc push_back(item: dataType) 
        {
            append(item);
        }

        proc push_back(item: dataType, items: dataType ...?k) 
        {
            this.append(item);
            for i in 1..k do
                this.append(items(i));
        }

        /* TODO: Check: The dataType stored in ull should be same as this one */
        /* Warning: The result of this extend is not as one would expect for a regular linked list */
        /* Because we are appending one by one to an ULL */
        proc extend(ull: UnrolledLinkedList(dataType))
        {
            if (ull.size != 0)
            {
                for i in ull do
                    this.append(i);
            }
        }

        /* pop: Delete and return last element */
        /* halts if called on an empty list */
        proc pop()
        {
            if (head == nil || tail == nil)
            {
                halt("Pop called on empty list");
            }

            var popElem = tail!.data.pop();
            tail!.numberOfItems -= 1;
            size -= 1;

            var temp = head;
            if (tail!.numberOfItems == 0) 
            {
                if (temp!.next == nil) 
                {
                    head = nil;
                    tail = nil;
                    return popElem;
                }

                else 
                {
                    while (temp!.next!.next != nil) do
                        temp = temp!.next;

                    var temp2 = temp!.next;
                    delete temp2;

                    temp!.next = nil;
                    tail = temp;
                }
            }

            var n: int = numberOfElementsInEachNode;
            var midInd: int = if n % 2 == 1 then n/2 + 1 else n/2;

            if (tail!.numberOfItems < midInd)
            {
                temp = head;

                if (temp!.next == nil)
                {
                    tail = head;
                    return popElem;
                }

                while (temp!.next!.next != nil) do
                    temp = temp!.next;

                // merge tail and its previous node
                while (!(temp!.next!.data.isEmpty()))
                {
                    temp!.data.append(temp!.next!.data.pop(1));
                    temp!.numberOfItems += 1;
                    temp!.next!.numberOfItems -= 1; // not really needed
                }
                
                // delete current tail and update it
                var temp2 = temp!.next;
                delete temp2;
                temp!.next = nil;
                tail = temp;
            }

            return popElem;
        }

        /* Delete item */
        /* Halts if called on empty list */
        /* Does nothing if item is not found */
        proc deleteItem(item: dataType) throws
        {
            if (head == nil)
            {
                halt("Delete item called on empty list.");
            }
            else
            {
                var temp = head;
                var reached = false;

                while (temp != nil)
                {
                    for itm in temp!.data
                    {
                        if (itm == item)
                        {
                            reached = true;
                            break;
                        }
                    }
                    if (reached)
                    {
                        break;
                    }
                    temp = temp!.next;
                }

                if (!reached)
                {
                    // the item was not found
                    return;
                }

                temp!.data.remove(item);
                temp!.numberOfItems -= 1;
                size -= 1;

                if (temp!.next == nil)
                {
                    writeln("At tail!");
                    // if we are at the tail, and tail's data is empty
                    // delete the tail node and set tail properly
                    if (temp!.data.isEmpty())
                    {
                        var temp2 = head;

                        while (temp2!.next!.next != nil) {
                            temp2 = temp2!.next;
                        }

                        tail = temp2;
                        delete temp2!.next;
                    }
                    writeln("Tail data: ", tail!.data);

                    return;
                }

                while (temp!.numberOfItems < numberOfElementsInEachNode)
                {
                    temp!.data.append(temp!.next!.data.pop(1));
                    temp!.next!.numberOfItems -= 1;
                    temp!.numberOfItems += 1;
                }

                var n: int = numberOfElementsInEachNode;
                var midInd: int = if n % 2 == 1 then n/2 + 1 else n/2;

                if (temp!.next!.numberOfItems < midInd)
                {
                    // merge temp!.next and temp
                    while (!(temp!.next!.data.isEmpty()))
                    {
                        temp!.data.append(temp!.next!.data.pop(1));
                        temp!.numberOfItems += 1;
                        temp!.next!.numberOfItems -= 1; // not really needed
                    }
                    
                    // delete temp!.next
                    var temp2 = temp!.next;

                    temp!.next = temp2!.next;

                    if (temp2!.next == nil) {
                        temp!.next = nil;
                        tail = temp;
                    }

                    delete temp2;
                }
            }
        }

        /* Returns true if key exists in the ULL */
        proc contains(key: dataType)
        {
            var found: bool = false;
            var temp = head;

            while (temp != nil)
            {
                for item in temp!.data 
                {
                    if (item == key)
                    {
                        found = true;
                        break;
                    }
                }
                temp = temp!.next;
            }
            return found;
        }

        /* Index the list via subscript */
        /* returns nil if i is out of bounds */
        /* Note: i is 1-based */
        pragma "no doc"
        proc this(i: int) ref: dataType
        {
            if (i > size) then
                halt("Index out of bounds!");

            var temp = head;
            var count = 0;

            while (temp != nil)
            {
                for itm in temp!.data
                {
                    count += 1;
                    if (count == i) {
                        ref refToItem = itm;
                        return refToItem;
                    }
                }
                
                temp = temp!.next;
            }
            halt("Index out of bounds!");
        }

        /* Returns reference to item if found */
        /* else halts */
        /* TODO: how else can we return that we couldn't find the key? */
        proc find(key: dataType) ref throws
        {
            var temp = head;

            if (head == nil)
            {
                halt("find() called on empty list.");
            }

            while (temp != nil)
            {
                for item in temp!.data 
                {
                    if (item == key)
                    {
                        ref foundItem = item;
                        return foundItem;
                    }
                }
                temp = temp!.next;
            }
            halt("Key not found.");
        }

        /* Returns reference to last element */
        /* Throws ListEmptyError if the list is empty */
        proc first() ref throws
        {
            if (head != nil) {
                try {
                    ref firstElem = head!.data.first();
                    return firstElem;
                }
                catch {
                    throw new owned ListEmptyError();
                }
            }
            else {
                throw new owned ListEmptyError();
            }
        }

        /* Returns reference to last element */
        /* Throws ListEmptyError if list is empty */
        proc last() ref throws
        {
            if (head != nil && tail != nil) {
                try {
                    ref lastElem = tail!.data.last();
                    return lastElem;
                }
                catch {
                    throw new owned ListEmptyError();
                }
            }
            else {
                throw new owned ListEmptyError();
            }
        }

        /* writeThis() overloaded */
        /* Binary format writing not yet supported*/
        /* TODO: Fix formatting after last element */
        proc writeThis(f)
        {
            f <~> new ioLiteral("[");

            /*
            for i in this
            {
                f <~> i <~> new ioLiteral(", ");
            }*/

            var temp = head;

            while (temp != nil) {
                for i in temp!.data do
                    f <~> i <~> new ioLiteral(", ");
                
                f <~> new ioLiteral(" / ");
                temp = temp!.next;
            }

            f <~> new ioLiteral("]");
        }

        /* Clear the list */
        proc destroy()
        {
            var temp = head;

            while (temp != nil)
            {
                var next = temp!.next;
                delete temp;
                temp = next;
            }
            head = nil;
            tail = nil;
            size = 0;
        }

        /* Another name for destroy() */
        inline proc clear() {
            destroy();
        }

        /* Destructor */
        pragma "no doc"
        proc deinit()
        {
            destroy();
        }
    }
}