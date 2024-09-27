<script lang="ts">
  import { translateYProperty } from "@nativescript/core";
  let message: string = "wut";
  import insomnia from "nativescript-insomnia";

  insomnia.keepAwake().then(function () {
    console.log("insomnia acitve");
  });
</script>

<page>
  <actionBar class="tit">
    <label class="info">
      <formattedString>
        <span text="title" />
      </formattedString>
    </label>
  </actionBar>

  <rootLayout height="100%" width="100%" horizontalAlignment="center">
    <dockLayout stretchLastChild="false" backgroundColor="#000" color="#fff">
      <label
        text="asdas:"
        dock="bottom"
        horizontalAlignment="center"
        height="40"
        backgroundColor="#000"
      />
    </dockLayout>
    <flexboxLayout flexDirection="row">
      <textView
        boxShadow="-20px 20px #fff"
        borderRadius="5px"
        borderWidth="5px"
        editable={true}
      >
        <formattedString><span text="what"> </span> </formattedString>
      </textView>
    </flexboxLayout>
  </rootLayout>
</page>

<style>
  page {
    background-color: #000;
    color: #fff;
    font-family: "GohuFont uni11 Nerd Font Mono";
  }

  actionBar {
    background-color: #000;
    color: #fff;
    font-family: "GohuFont uni11 Nerd Font Mono";
  }

  textView {
    background-color: #000;
    height: 1000px;
    width: 1000px;
    margin: 10px;
    border-style: dotted;
  }

  flexboxLayout {
    align-items: center;
    justify-content: center;
  }
</style>
