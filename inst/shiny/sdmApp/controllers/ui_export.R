output$download_cor_mat <- downloadHandler(
  filename = function() {
    paste('correlation_matrix', Sys.Date(), '.csv', sep='')
  },
  content = function(file) {
    utils::write.csv(mat(), file)
  }
)

output$download_Marg_Spec <- downloadHandler(
  filename = function() {
    paste('Marg_Spec', Sys.Date(), '.csv', sep='')
  },
  content = function(file) {
    utils::write.csv(marg_spec(), file)
  }
)

output$download_cor_plot <- downloadHandler(
  filename =  function() {
    paste("cor_plot", input$plot_type_cor, sep=".")
  },
  # content is a function with argument file. content writes the plot to the device
  content = function(file) {
    if(input$plot_type_cor == "png"){
      grDevices::png(file) # open the pdf device
      print(Cor_plotInput())
      dev.off()  # turn the device off
    }

    else{
      grDevices::pdf(file) # open the pdf device
      print(Cor_plotInput())
      dev.off()  # turn the device off
    }
  }
)

output$download_enfa_scatter <- downloadHandler(
  filename =  function() {
    paste("ENFA", Sys.Date(), sep=".png")
  },
  # content is a function with argument file. content writes the plot to the device
  content = function(file) {
      grDevices::png(file)
      print(enfa_plotInput())
      dev.off()  # turn the device off
  }
)



output$download_Bioclim <- downloadHandler(
  filename =  function() {
    paste("Bioclim_N_Blocking", input$plot_type_Bioclim, sep=".")
  },
  # content is a function with argument file. content writes the plot to the device
  content = function(file) {
    if(input$plot_type_Bioclim == "png"){
      # grDevices::png(file) # open the pdf device
      # Cor_plotInput()
      # dev.off()  # turn the device off
    }

    if(input$plot_type_Bioclim == "png"){
      # grDevices::png(file) # open the pdf device
      # Cor_plotInput()
      # dev.off()  # turn the device off
    }

    if(input$plot_type_Bioclim == "tif"){
      #r <- raster(system.file("external/test.grd", package="raster"))
      res <- writeRaster(load.occ$Bioclim, filename=file, format="GTiff", overwrite=TRUE)

      # Show the corresponding output filename
      print(res@file@name)

      # Rename it to the correct filename
      file.rename(res@file@name, file)
    }
  }
)
