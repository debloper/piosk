$(document).ready(function () {
    const $urlList = $("#urls ul.list-group");

    // Use event delegation to highlight inputs when they are changed.
    $('#urls').on('change', '.duration-input, .cycles-input', function () {
        $(this).addClass('input-changed');
    });

    // Add a separate click listener to the Apply button just to remove the highlight.
    // This will fire alongside the listener in script.js that saves the data.
    $('#execute').on('click', function () {
        $('.input-changed').removeClass('input-changed');
    });

    // --- DRAG & DROP REORDER LOGIC ---
    let draggingItem = null;

    // Start dragging from the handle
    $urlList.on("dragstart", ".drag-handle", function (e) {
        draggingItem = $(this).closest("li")[0];
        draggingItem.classList.add("dragging");
        const dataTransfer = e.originalEvent.dataTransfer;
        dataTransfer.effectAllowed = "move";
        dataTransfer.setData("text/plain", "");
    });

    // End dragging
    $urlList.on("dragend", ".drag-handle", function () {
        if (draggingItem) {
            draggingItem.classList.remove("dragging");
        }
        $urlList.find("li.list-group-item").removeClass("over");
        draggingItem = null;
    });

    // Handle dragging over the list
    $urlList.on("dragover", function (e) {
        e.preventDefault();
        if (!draggingItem) return;

        const afterElement = getDragAfterElement(this, e.clientY);
        $urlList.find("li.list-group-item").removeClass("over");

        if (afterElement) {
            $(afterElement).addClass("over");
            this.insertBefore(draggingItem, afterElement);
        } else {
            this.appendChild(draggingItem);
        }
    });

    // Helper function to find the element to drop before
    function getDragAfterElement(container, y) {
        const draggableElements = [...container.querySelectorAll("li.list-group-item:not(.dragging)")];

        return draggableElements.reduce(
            (closest, child) => {
                const box = child.getBoundingClientRect();
                const offset = y - box.top - box.height / 2;
                if (offset < 0 && offset > closest.offset) {
                    return { offset: offset, element: child };
                } else {
                    return closest;
                }
            },
            { offset: Number.NEGATIVE_INFINITY }
        ).element;
    }
});