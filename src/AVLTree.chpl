module AVLTree
{
    private use LockFreeStack;

    pragma "no doc"
    class AVLTreeNode
    {
        type dataType;
        var data: dataType;

        var left: unmanaged AVLTreeNode(dataType)?;
        var right: unmanaged AVLTreeNode(dataType)?;

        var height: int;

        proc init(type dataType, data: dataType)
        {
            this.dataType = dataType;
            this.left = nil;
            this.right = nil;
            this.height = 1;
            this.data = data;
        }
    }

    /* Some utility functions: */
    /* These functions are kept outside record AVLTree as they are not meant
       to be called by the user. */

    pragma "no doc"
    // Utility function to get maximum of two integers:
    private inline proc maxOf(a: int, b: int) {
        return (if a > b then a else b);
    }

    pragma "no doc"
    // The utility functions getHeight and getBalanceFactor
    // can be put inside class AVLTreeNode, but then
    // explicit nil-checking would be required elsewhere
    proc getHeight(node: AVLTreeNode?)
    {
        if (node == nil) {
            return 0;
        }
        return node!.height;
    }

    pragma "no doc"

    // Gets balance factor of a node
    proc getBalanceFactor(node: AVLTreeNode?)
    {
        if (node == nil) {
            return 0;
        }
        return (getHeight(node!.left) - getHeight(node!.right));
    }

    pragma "no doc"
    // Utility function to perform right rotation
    // at 'node'
    // Returns the new root at that position
    private proc rotateRight(node: AVLTreeNode)
    {
        var nodeLeft = node!.left;
        var nodeLeftRightTree = nodeLeft!.right;

        // perform rotation
        nodeLeft!.right = node;
        node!.left = nodeLeftRightTree;

        node!.height = maxOf(getHeight(node!.left), getHeight(node!.right)) + 1;
        nodeLeft!.height = maxOf(getHeight(node!.left), getHeight(node!.right)) + 1;

        return nodeLeft;
    }

    pragma "no doc"
    // Utility function to perform left rotation
    // at 'node'
    // Returns the new root at that position
    private proc rotateLeft(node: AVLTreeNode)
    {
        var nodeRight = node!.right;
        var nodeRightLeftTree = nodeRight!.left;

        // perform rotation
        nodeRight!.left = node;
        node!.right = nodeRightLeftTree;

        node!.height = maxOf(getHeight(node!.left), getHeight(node!.right)) + 1;
        nodeRight!.height = maxOf(getHeight(node!.left), getHeight(node!.right)) + 1;

        return nodeRight;
    }

    pragma "no doc"
    // Utility function to insert 'nodeToIns' at the subtree rooted
    // at 'node' and re-balance by performing rotations after each insertion
    // returns the new root of the subtree it was inserted in
    // Steps for AVL Tree:
    // 1. Standard BST insert
    // 2. Update balance factor of current node
    // 3. Perform necessary rotations to balance current node if needed

    private proc recurInsert(type dataType, key: dataType, node: AVLTreeNode?)
    {
        if (node == nil) {
            return new unmanaged AVLTreeNode(key);
        }

        if (key <= node!.data) 
        {
            node!.left = recurInsert(dataType, node!.right, key);
        }
        else if (key > node!.data) 
        {
            node!.right = recurInsert(dataType, node!.left, key);
        }

        node!.height = maxOf(getHeight(node!.left), getHeight(node!.right)) + 1;

        // Perform rotations after checking balance
        var bal: int = getBalanceFactor(node);

        if (bal > 1 && key < node!.left!.data) // LL
        {
            return rotateRight(node);
        }
        if (bal < -1 && key > node!.right!.data) // RR
        {
            return rotateLeft(node);
        }

        if (bal > 1 && key > node!.left!.data) // LR
        {
            node!.left = rotateLeft(node!.left);
            return rotateRight(node);
        }
        if (bal < -1 && key < node!.right!.data) // RL
        {
            node!.right = rotateRight(node!.right);
            return rotateLeft(node);
        }

        // If no rotations are needed, just return the node
        return node;
    }

    pragma "no doc"
    // Utility function to recursively delete the node with key 'key'
    // in the subtree with root node 'node'
    // Returns root of the modified subtree
    private proc recurDelete(type dataType, key: dataType, node: AVLTreeNode?)
    {
        if (node == nil) {
            return nil;
        }

        if (key < node!.data) 
        {
            node!.left = recurDelete(dataType, node, key);
        }
        else if (key > node!.data) 
        {
            node!.right = recurDelete(dataType, node, key);
        }
        else // if we're here, this is the node to be deleted
        {
            if (node!.left == nil || node!.right == nil)
            {
                // this node has only one child or no child
                var temp: AVLTreeNode = if node!.right == nil then node!.left else node!.right;

                if (temp == nil)
                {
                    // no child
                    temp = node;
                    node = nil;
                }
                else
                {
                    // one child
                    node!.data = temp!.data;
                }
                delete temp;
            }
            else
            {
                // if 2 children, replace by minimum value of right subtree
                // (inorder successor)
                var temp = node!.right;

                // go to the leftmost node in the right subtree
                while (temp!.left != nil) do
                    temp = temp!.left;
                
                node!.data = temp!.data;
                node!.right = recurDelete(dataType, node!.right, temp!.data);
            }

            // a quick nil check
            if (node == nil) {
                return nil;
            }

            node!.height = maxOf(getHeight(node!.left), getHeight(node!.right)) + 1;

            // Perform rotations after checking balance
            var bal: int = getBalanceFactor(node);

            if (bal > 1 && getBalanceFactor(node!.left) >= 0) // LL
            {
                return rotateRight(node);
            }
            if (bal < -1 && getBalanceFactor(node!.right) <= 0) // RR
            {
                return rotateLeft(node);
            }

            if (bal > 1 && key > getBalanceFactor(node!.left) < 0) // LR
            {
                node!.left = rotateLeft(node!.left);
                return rotateRight(node);
            }
            if (bal < -1 && getBalanceFactor(node!.right) > 0) // RL
            {
                node!.right = rotateRight(node!.right);
                return rotateLeft(node);
            }

            // If no rotations are needed, just return the node
            return node;
        }
    }

    pragma "no doc"
    // Recursive utility function that stores the last node of the BST rooted at 'root' in 'lastNode'
    // and its parent in 'lastNodeParent'
    proc computeLastNodeAndParent(root: AVLTreeNode, level: int, parent: AVLTreeNode, lastNode: AVLTreeNode, lastNodeParent: AVLTreeNode)
    {
        // base case
        if (root == nil) {
            return;
        }

        if (level == 1)
        {
            lastNode = root;
            lastNodeParent = parent;
        }
        computeLastNodeAndParent(root.left, level-1, root, lastNode, lastNodeParent);
    }

    record AVLTree
    {
        type dataType;
        var root: unmanaged AVLTreeNode(dataType)?;
        var lastNode: AVLTreeNode;
        var parentOfLastNode: AVLTreeNode;

        proc init(type dataType)
        {
            this.dataType = dataType;
            root = nil;
            lastNode = nil;
            parentOfLastNode = nil;
        }

        /* Insert 'data' into the AVL tree */
        /* Note: Insert and delete options DO NOT update lastNode and parentOfLastNode */
        /* to preserve standard time complexity */
        proc insertElement(data: dataType)
        {
            root = recurInsert(dataType, data, root);
        }

        /* Another name for insertElement(data) */
        inline proc push(data: dataType)
        {
            insertElement(data);
        }

        /* Delete node with key 'key' from the AVL tree. Halts if called on empty tree. */
        /* Note: Insert and delete options DO NOT update lastNode and parentOfLastNode */
        /* to preserve standard time complexity */
        proc deleteElement(key: dataType)
        {
            if (root == nil) {
                halt("error: deletion of element from empty AVLTree");
            }
            root = recurDelete(dataType, key, root);
        }

        /* Deletes the node with key 'key'. This is another name for deleteElement(key) */
        inline proc pop(key: dataType)
        {
            deleteElement(key);
        }

        /* Can be used to check if tree is empty or not */
        proc isEmpty(): bool
        {
            if (root == nil) {
                return true;
            }
            return false;
        }

        /* Updates lastNode and parentOfLastNode and returns last leaf node's data */
        /* Halts if called on empty tree. */
        /* Note: Insert and delete options DO NOT update lastNode and parentOfLastNode */
        /* to preserve standard time complexity */
        proc last(): dataType
        {
            if (root == nil) {
                halt("error: last() called on empty AVLTree");
            }

            if (root!.left == nil && root!.right == nil) 
            {
                return root!.data;
            }
            else
            {
                var lastNodeLevel = getHeight(root);
                computeLastNodeAndParent(root, lastNodeLevel, nil, this.lastNode, this.lastNodeParent);
                return lastNode!.data;
            }
        }

        /* Returns data of root */
        /* Halts if called on empty tree. */
        proc first()
        {
            if (root == nil) {
                halt("error: first() called on empty AVLTree");
            }

            return root!.data;
        }

        /* Delete last element and return its value*/
        proc pop(): dataType
        {
            if (root == nil) {
                halt("error: pop() called on empty AVLTree");
            }

            if (root!.left == nil && root!.right == nil) 
            {
                var data = root!.data;
                root = nil;
                return data;
            }

            var lastNodeLevel = getHeight(root);
            computeLastNodeAndParent(root, lastNodeLevel, nil, this.lastNode, this.lastNodeParent);

            if (lastNode != nil && parentOfLastNode != nil)
            {
                var lastData = lastNode!.data;

                if (parentOfLastNode!.right != nil) {
                    parentOfLastNode!.right = nil;
                }
                else {
                    parentOfLastNode!.left = nil;
                }
            }
            else {
                halt("error: unable to pop last element from AVLTree");
            }
        }

        /*  Iterates through the AVL tree by performing inorder traversal */
        iter inOrder()
        {
            if (root == nil) {
                return;
            }

            var stack = new LockFreeStack(AVLTreeNode);

            var curr = root;
            var isEmpty = false;
            var temp: AVLTreeNode;

            while (curr != nil || !isEmpty)
            {
                while (curr != nil)
                {
                    stack.push(curr);
                    curr = curr!.left;
                }

                (isEmpty, curr) = stack.pop();
                
                yield curr!.data;
                curr = curr!.right;
            }
            stack.tryReclaim();
        }

        /* Iterates through the AVL tree by performin inorder traversal */
        iter these() 
        {
            for i in this.inOrder() do
                yield i;
        }

        /* Iterates through the AVL tree by performing its preorder traversal */
        iter preOrder()
        {
            if (root == nil) {
                return;
            }

            var stack = new LockFreeStack(AVLTreeNode);
            stack.push(root);

            var isEmpty = false;
            var node: AVLTreeNode;

            while (!isEmpty)
            {
                (isEmpty, node) = stack.pop();
                
                yield node!.data;

                if (node!.right != nil) {
                    stack.push(node!.right);
                }
                if (node!.left != nil) {
                    stack.push(node!.left);
                }
            }
            stack.tryReclaim();
        }

        /* Iterates through the AVL tree by performing postOrder traversal */
        iter postOrder()
        {
            if (root == nil) {
                return;
            }

            // An implementation with 2 stacks
            var stack1 = new LockFreeStack(AVLTreeNode);
            var stack2 = new LockFreeStack(AVLTreeNode);

            stack1.push(root);

            var isEmpty1 = false;
            var node: AVLTreeNode;

            while (!isEmpty1)
            {
                (isEmpty1, node) = stack1.pop();

                stack2.push(node);

                if (node!.left != nil) {
                    stack1.push(node!.left);
                }
                if (node!.right != nil) {
                    stack1.push(node!.right);
                }
            }

            // Now we have the reverse of what shoulde be the postOrder in stack2
            // Hence emptying stack2 will give the correct order
            var isEmpty2 = false;

            while (!isEmpty2) 
            {
                (isEmpty2, node) = stack2.pop();
                yield node!.data;
            }

            stack1.tryReclaim();
            stack2.tryReclaim();
        }

        /* Outputs inorder traversal of the tree */
        proc writeThis(f)
        {
            for i in this {
                f <~> i <~> new ioLiteral(" ");
            }
        }

        /* Clears the tree */
        proc destroy()
        {
            while (!isEmpty()) do
                pop();
        }

        /* Another name for destroy() */
        inline proc clear() {
            destroy();
        }

        proc deinit()
        {
            destroy();
        }
    }
}