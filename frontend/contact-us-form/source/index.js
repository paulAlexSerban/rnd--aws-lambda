const form = document.querySelector("form");
form.addEventListener("submit", (event) => {
  // prevent the form submit from refreshing the page
  event.preventDefault();

  const nameInput = document.getElementById("name");
  const emailInput = document.getElementById("email");
  const messageInput = document.getElementById("message");

  // Validate input
  if (!nameInput.value || !emailInput.value || !messageInput.value) {
    document.getElementById("result-text").innerText = "Please fill in all required fields.";
    return;
  }

  const endpoint = "https://add-your-own-path.execute-api.eu-central-1.amazonaws.com/default/sendContactEmail";
  const body = JSON.stringify({
    senderName: nameInput.value,
    senderEmail: emailInput.value,
    message: messageInput.value,
  });
  const requestOptions = {
    method: "POST",
    body,
  };

  fetch(endpoint, requestOptions)
    .then((response) => {
      if (!response.ok) throw new Error("Error in fetch");
      return response.json();
    })
    .then((response) => {
      document.getElementById("result-text").innerText = "Email sent successfully!";
    })
    .catch((error) => {
      console.error(error);
      document.getElementById("result-text").innerText = "An error occurred. Please try again later.";
    });
});
