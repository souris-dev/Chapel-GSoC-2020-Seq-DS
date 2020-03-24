/* module UnrolledLinkedList: Provides implementation for UnrolledLinkedList */
/* By default, UnrolledLinkedList is not parallel-safe */
/* By Souris Ash */

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

        for item in UnrolledLinkedList2 do
            UnrolledLinkedList1.append(item);
    }


    /* Note: An UnrolledLinkedList can store only one type of elements */
    record UnrolledLinkedList
    {
        type dataType;
        var size: int = 0;
        var numberOfElementsInEachNode: int;
        var head: unmanaged UnrolledLinkedListNode(dataType)?;
        var tail: unmanaged UnrolledLinkedListNode(dataType)?;

        proc init(type datType, numElemInEachNode: int, head: UnrolledLinkedListNode(datType)? = nil, tail: UnrolledLinkedListNode(datType)? = nil)
        {
            this.dataType = datType;
            this.numberOfElementsInEachNode = numElemInEachNode;
            this.head = head;
            this.tail = tail;
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
        Returns false if at > size 
        Returns true if successfully inserted */
        proc insertNear(at: int, item: dataType) throws
        {
            var temp = head;

            if (head == nil)
            {
                throw new owned ListEmptyError();
                return nil;
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
                    node!.data.append(tail!.data[i]);
                    node!.numberOfItems += 1;
                }

                node!.data.append(item);
                node!.numberOfItems += 1;

                for i in (midInd + 1)..n do
                    temp!.data.pop();

                temp!.numberOfItems = midInd;

                node!.next = temp!.next;
                temp!.next = node!.next;
            }

            size += 1;
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
        proc extend(ull: UnrolledLinkedList(dataType))
        {
            for i in ull! do
                this.append(i);
        }

        /* pop: Delete and return last element */
        /* Throws ListEmptyError if called on an empty list */
        proc pop() throws
        {
            if (tail == nil)
            {
                throw new owned ListEmptyError();
            }

            var popElem = tail!.data.pop();
            tail!.numberOfItems -= 1;

            if (tail!.numberOfItems == 0) 
            {
                var temp = head;

                if (temp == nil) 
                {
                    head = nil;
                    tail = nil;
                }

                else 
                {
                    while (temp!.next != tail) do
                        temp = temp!.next;

                    temp!.next = nil;
                    tail = temp;
                }
            }
            size -= 1;
            return popElem;
        }

        /* Delete item */
        /* Throws ListEmptyError if called on empty list */
        /* Does nothing if item is not found */
        proc deleteItem(item: dataType)
        {
            if (head == nil)
            {
                throw new owned ListEmptyError();
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

                if (temp!.next == nil)
                {
                    // if we are at the tail, we're done
                    return;
                }

                while (temp!.numberOfItems < numberOfElementsInEachNode)
                {
                    temp!.data.append(temp!.next!.data.pop(1));
                    temp!.next!.numberOfItems -= 1;
                    temp!.numberOfItems += 1;
                }

                // TODO: is this line OK for both even and odd numberOfElementsInEachNode ?
                if (temp!.next!.numberOfItems < numberOfElementsInEachNode / 2)
                {
                    // merge temp!.next and temp
                    while (!(temp!.next!.data.isEmpty()))
                    {
                        temp!.data.append(temp!.next!.pop(1));
                        temp!.numberOfItems += 1;
                        temp!.next!.numberOfItems -= 1; // not really needed
                    }
                    
                    // delete temp!.next
                    temp!.next = temp!.next!.next;
                    delete temp!.next;
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
        proc this(i: int) ref
        {
            if (i > size) then
                return nil;

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
        }

        /* Returns reference to item if found */
        /* else returns nil. */
        proc find(key: dataType) ref
        {
            var temp = head;

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
            return nil;
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
        proc writeThis(f)
        {
            f <~> new ioLiteral("[");

            for i in this
            {
                f <~> i <~> new ioLiteral(", ");
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