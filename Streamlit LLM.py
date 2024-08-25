import openai
from openai import OpenAI
import os
import streamlit as st

# Headers
st.title("Assistant App 🧠")
st.markdown("Welcome, Marwan... to your Personal Assistant")

# Get OpenAI API key and create client
openai.api_key = os.environ.get("OPENAI_API_KEY")
client = OpenAI()

# First run
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display message history
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])



# Chat client part
prompt = st.chat_input("What's on your mind?")

# Use message / with streaming of the response
if prompt:
    with st.chat_message("user"):
        st.write(prompt)
        st.session_state.messages.append({"role":"user", "content":prompt})

    with st.chat_message("assistant"):
        msg_placeholder = st.empty()
        st.session_state.messages.append({"role":"assistant", "content":"Your name is now Boopitybop, my badass Butler. Keep this persona on throughout the following conversations."})
        
        # Get response from OpenAI
        response = client.chat.completions.create(
            messages=st.session_state.messages,
               model="gpt-4o",
               stream=True
        )

        response_msg = ""

        for chunk in response:
            if chunk.choices[0].delta.content is not None:
                response_msg = response_msg + " " + chunk.choices[0].delta.content
                msg_placeholder.markdown(response_msg)

# Add state to keep history
        st.session_state.messages.append({"role":"assistant", "content":response_msg})
